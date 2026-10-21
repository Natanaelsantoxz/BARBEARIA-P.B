// ============================================================
// CONFIGURAÇÃO DO SITE - Barbearia P.B.
// Preencha SÓ as 2 linhas marcadas com  <<< PREENCHER
// (Supabase > Project Settings > API)
// ============================================================

const SUPABASE_URL = "https://jbggyfpycaenejoqynbl.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_DcCUFjlBJupksriPNzkSyw_AoM6nDyf";

// Conexão com o banco (usada por index.html, admin.html e reset-password.html)
const db = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Funcionamento da barbearia
const CONFIG = {
  ABRE: "09:00",          // horário de abertura
  FECHA: "19:00",         // horário de fechamento
  PASSO: 30,              // intervalo entre horários, em minutos
  DIAS_FECHADOS: [0]      // 0 = domingo, 1 = segunda ... 6 = sábado
};

// Serviços: ajuste nomes, preços (R$) e duração (min) como quiser
const SERVICOS = [
  { nome: "Corte",           preco: 35, dur: 30 },
  { nome: "Barba",           preco: 25, dur: 30 },
  { nome: "Sobrancelha",     preco: 10, dur: 15 },
  { nome: "Pigmentação",     preco: 30, dur: 30 }
];

// ---------- Funções auxiliares (não mexer) ----------
const brl = v => Number(v).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });

// "09:30" ou "09:30:00" -> 570
const toMin = hm => {
  const [h, m] = String(hm).split(":");
  return Number(h) * 60 + Number(m);
};

// 570 -> "09:30"
const toHM = min => String(Math.floor(min / 60)).padStart(2, "0") + ":" + String(min % 60).padStart(2, "0");
