// ====== CONFIGURE AQUI ======
const CONFIG = {
  SUPABASE_URL: "https://SEU-PROJETO.supabase.co",
  SUPABASE_ANON_KEY: "SUA_CHAVE_ANON_PUBLICA",
  ABRE: "09:00", FECHA: "19:00", PASSO: 30, // minutos entre horários
  DIAS_FECHADOS: [0],                       // 0 = domingo
};
// Tabela de preços da barbearia (duração em minutos)
const SERVICOS = [
  { nome: "Sobrancelha avulsa", preco: 15, dur: 15 },
  { nome: "Acabamento (pezinho)", preco: 15, dur: 15 },
  { nome: "Barba", preco: 40, dur: 30 },
  { nome: "Corte de cabelo", preco: 40, dur: 30 },
  { nome: "Corte infantil", preco: 40, dur: 30 },
  { nome: "Combo TALENT (cabelo + sobrancelha)", preco: 45, dur: 45 },
  { nome: "Combo GOLD (cabelo + barba)", preco: 75, dur: 60 },
  { nome: "Combo MASTER (cabelo + barba + sobrancelha)", preco: 80, dur: 75 },
];
const db = supabase.createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);
const brl = n => n.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
const toMin = t => { const [h, m] = t.split(":"); return +h * 60 + +m; };
const toHM = m => String(Math.floor(m / 60)).padStart(2, "0") + ":" + String(m % 60).padStart(2, "0");
