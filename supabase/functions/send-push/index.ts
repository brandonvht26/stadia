import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { create, getNumericDate } from "https://deno.land/x/djwt@v3.0.2/mod.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Decodifica la Service Account desde el secret en base64
function getServiceAccount() {
  const base64 = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_BASE64")!;
  const jsonStr = atob(base64);
  return JSON.parse(jsonStr);
}

// Convierte la clave privada PEM a un CryptoKey importable por Web Crypto
async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemContents = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  return await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
}

// Genera un access_token de Google OAuth2 usando la Service Account
async function getGoogleAccessToken(): Promise<{ token: string; projectId: string }> {
  const sa = getServiceAccount();
  const key = await importPrivateKey(sa.private_key);

  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      exp: getNumericDate(3600),
      iat: getNumericDate(0),
    },
    key
  );

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await response.json();
  if (!data.access_token) {
    throw new Error(`No se pudo obtener access_token: ${JSON.stringify(data)}`);
  }

  return { token: data.access_token, projectId: sa.project_id };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Esta función solo debe ser llamada internamente (service_role), 
    // nunca directo desde el cliente Flutter.
    const authHeader = req.headers.get("Authorization") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    if (!authHeader.includes(serviceRoleKey)) {
      return new Response(JSON.stringify({ error: "No autorizado" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { userId, title, body, data } = await req.json();
    if (!userId || !title || !body) {
      return new Response(JSON.stringify({ error: "userId, title y body son requeridos" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data: tokens, error: tokensError } = await supabaseAdmin
      .from("device_tokens")
      .select("fcm_token")
      .eq("user_id", userId);

    if (tokensError || !tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0, message: "El usuario no tiene dispositivos registrados" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { token: accessToken, projectId } = await getGoogleAccessToken();

    let sentCount = 0;
    const invalidTokens: string[] = [];

    for (const row of tokens) {
      const fcmToken = row.fcm_token;
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: fcmToken,
              notification: { title, body },
              data: data ?? {},
            },
          }),
        }
      );

      if (response.ok) {
        sentCount++;
      } else {
        const errBody = await response.json();
        // Token inválido o desregistrado: lo marcamos para limpiar de la BD
        if (errBody?.error?.status === "NOT_FOUND" || errBody?.error?.status === "INVALID_ARGUMENT") {
          invalidTokens.push(fcmToken);
        }
      }
    }

    if (invalidTokens.length > 0) {
      await supabaseAdmin.from("device_tokens").delete().in("fcm_token", invalidTokens);
    }

    return new Response(JSON.stringify({ sent: sentCount, cleaned: invalidTokens.length }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});