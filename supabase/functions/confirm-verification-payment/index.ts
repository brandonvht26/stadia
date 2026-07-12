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

    const { data: payment, error: fetchError } = await supabaseAdmin
      .from("host_payments")
      .select("id, host_id, stripe_payment_intent_id, status")
      .eq("reception_id", receptionId)
      .eq("payment_type", "verification_fee")
      .order("created_at", { ascending: false })
      .limit(1)
      .single();

    if (fetchError || !payment) {
      return new Response(JSON.stringify({ error: "Pago no encontrado" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (payment.host_id !== user.id) {
      return new Response(JSON.stringify({ error: "No autorizado" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const paymentIntent = await stripe.paymentIntents.retrieve(payment.stripe_payment_intent_id);

    if (paymentIntent.status !== "succeeded") {
      return new Response(
        JSON.stringify({ error: `El pago no se ha completado (estado: ${paymentIntent.status})` }),
        { status: 402, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    await supabaseAdmin
      .from("host_payments")
      .update({ status: "confirmed", payment_date: new Date().toISOString() })
      .eq("id", payment.id);

    // Esto pasa el trigger trg_receptions_protect_verified porque usamos service_role
    await supabaseAdmin
      .from("receptions")
      .update({ is_verified: true })
      .eq("id", receptionId);

    return new Response(JSON.stringify({ success: true, isVerified: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});