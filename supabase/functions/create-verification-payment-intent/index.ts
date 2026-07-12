import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import Stripe from "https://esm.sh/stripe@14?target=deno";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2023-10-16",
  httpClient: Stripe.createFetchHttpClient(),
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const VERIFICATION_FEE_USD = 20.00; // Monto fijo, definido en el backend, nunca en el cliente

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "No autenticado" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { receptionId } = await req.json();
    if (!receptionId) {
      return new Response(JSON.stringify({ error: "receptionId requerido" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Validar que la recepción existe, es del host, y no está ya verificada
    const { data: reception, error: fetchError } = await supabaseAdmin
      .from("receptions")
      .select("id, host_id, is_verified")
      .eq("id", receptionId)
      .single();

    if (fetchError || !reception) {
      return new Response(JSON.stringify({ error: "Recepción no encontrada" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (reception.host_id !== user.id) {
      return new Response(JSON.stringify({ error: "No autorizado" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (reception.is_verified) {
      return new Response(JSON.stringify({ error: "Esta recepción ya está verificada" }), {
        status: 409,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const amountInCents = Math.round(VERIFICATION_FEE_USD * 100);

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInCents,
      currency: "usd",
      metadata: { reception_id: receptionId, host_id: user.id, type: "verification_fee" },
    });

    // Crear el registro de host_payments en 'pending'
    const { data: payment, error: insertError } = await supabaseAdmin
      .from("host_payments")
      .insert({
        host_id: user.id,
        reception_id: receptionId,
        amount: VERIFICATION_FEE_USD,
        payment_type: "verification_fee",
        status: "pending",
        stripe_payment_intent_id: paymentIntent.id,
      })
      .select("id")
      .single();

    if (insertError) {
      return new Response(JSON.stringify({ error: "Error al registrar el pago" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({ clientSecret: paymentIntent.client_secret, paymentId: payment.id }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});