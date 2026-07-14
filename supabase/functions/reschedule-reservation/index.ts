import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

    const { reservationId, newDate } = await req.json();
    if (!reservationId || !newDate) {
      return new Response(JSON.stringify({ error: "reservationId y newDate son requeridos" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data: reservation, error: fetchError } = await supabaseAdmin
      .from("reservations")
      .select("id, user_id, reception_id, event_date, status, reschedule_count, original_event_date")
      .eq("id", reservationId)
      .single();

    if (fetchError || !reservation) {
      return new Response(JSON.stringify({ error: "Reserva no encontrada" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (reservation.user_id !== user.id) {
      return new Response(JSON.stringify({ error: "No autorizado" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!["pending", "confirmed"].includes(reservation.status)) {
      return new Response(JSON.stringify({ error: "Solo se pueden reagendar reservas activas" }), {
        status: 409,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (reservation.reschedule_count >= 1) {
      return new Response(JSON.stringify({ error: "Esta reserva ya fue reagendada una vez" }), {
        status: 409,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Regla de 48 horas: se calcula sobre la fecha ACTUAL agendada, no la nueva
    const currentEventDate = new Date(reservation.event_date + "T00:00:00Z");
    const now = new Date();
    const hoursUntilEvent = (currentEventDate.getTime() - now.getTime()) / (1000 * 60 * 60);

    if (hoursUntilEvent < 48) {
      return new Response(
        JSON.stringify({ error: "Solo puedes reagendar con al menos 48 horas de anticipación" }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const newDateObj = new Date(newDate + "T00:00:00Z");
    if (newDateObj.getTime() <= now.getTime()) {
      return new Response(JSON.stringify({ error: "La nueva fecha debe ser futura" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verifica que la nueva fecha esté libre para esa recepción
    const { data: conflicting, error: conflictError } = await supabaseAdmin
      .from("reservations")
      .select("id")
      .eq("reception_id", reservation.reception_id)
      .eq("event_date", newDate)
      .in("status", ["pending", "confirmed"])
      .neq("id", reservationId);

    if (conflictError) {
      return new Response(JSON.stringify({ error: "Error al verificar disponibilidad" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (conflicting && conflicting.length > 0) {
      return new Response(JSON.stringify({ error: "La fecha seleccionada ya no está disponible" }), {
        status: 409,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { error: updateError } = await supabaseAdmin
      .from("reservations")
      .update({
        event_date: newDate,
        reschedule_count: reservation.reschedule_count + 1,
        original_event_date: reservation.original_event_date ?? reservation.event_date,
      })
      .eq("id", reservationId);

    if (updateError) {
      return new Response(JSON.stringify({ error: "Error al reagendar la reserva" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true, newDate }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});