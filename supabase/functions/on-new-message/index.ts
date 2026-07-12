import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const payload = await req.json();
    const message = payload.record; // Formato estándar de Database Webhooks

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data: chat, error } = await supabaseAdmin
      .from("chats")
      .select("user_id, host_id")
      .eq("id", message.chat_id)
      .single();

    if (error || !chat) {
      return new Response(JSON.stringify({ error: "Chat no encontrado" }), { status: 404 });
    }

    // El destinatario es el participante que NO envió el mensaje
    const recipientId = message.sender_id === chat.user_id ? chat.host_id : chat.user_id;

    await supabaseAdmin.functions.invoke("send-push", {
      headers: { Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}` },
      body: {
        userId: recipientId,
        title: "Nuevo mensaje",
        body: message.content.length > 80 ? message.content.slice(0, 80) + "..." : message.content,
        data: { type: "new_message", chatId: message.chat_id },
      },
    });

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 });
  }
});