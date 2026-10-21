-- Rode no Supabase: SQL Editor > New query > cole TUDO > Run
-- Pode rodar quantas vezes quiser (não dá erro se já existir).
-- E-mail do profissional: barbeariapb11@gmail.com

-- ===== Tabela de agendamentos =====
create table if not exists agendamentos (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  telefone text not null,
  servico text not null,
  preco numeric(8,2) not null,
  data date not null,
  hora time not null,
  duracao_min int not null,
  status text not null default 'agendado' check (status in ('agendado','concluido','cancelado')),
  criado_em timestamptz not null default now()
);

alter table agendamentos enable row level security;

drop policy if exists "cliente cria" on agendamentos;
create policy "cliente cria" on agendamentos for insert to anon
  with check (status = 'agendado');

drop policy if exists "profissional total" on agendamentos;
create policy "profissional total" on agendamentos for all to authenticated
  using ((auth.jwt() ->> 'email') = 'barbeariapb11@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'barbeariapb11@gmail.com');

-- ===== Horários ocupados (cliente vê só hora e duração) =====
create or replace function horarios_ocupados(dia date)
returns table(hora time, duracao_min int)
language sql security definer set search_path = public as $$
  select hora, duracao_min from agendamentos where data = dia and status <> 'cancelado'
$$;
grant execute on function horarios_ocupados(date) to anon, authenticated;

-- ===== Impede dois agendamentos no mesmo horário =====
create or replace function checa_conflito() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from agendamentos a
    where a.data = new.data and a.status <> 'cancelado'
      and new.hora < a.hora + make_interval(mins => a.duracao_min)
      and a.hora < new.hora + make_interval(mins => new.duracao_min))
  then raise exception 'Horário indisponível'; end if;
  return new;
end $$;

drop trigger if exists trg_conflito on agendamentos;
create trigger trg_conflito before insert on agendamentos
  for each row execute function checa_conflito();

-- ===== WhatsApp do profissional =====
create table if not exists configuracoes (
  id int primary key default 1 check (id = 1),
  whatsapp text not null default ''
);
insert into configuracoes (id) values (1) on conflict (id) do nothing;
alter table configuracoes enable row level security;

drop policy if exists "todos leem" on configuracoes;
create policy "todos leem" on configuracoes for select to anon, authenticated using (true);

drop policy if exists "profissional altera" on configuracoes;
create policy "profissional altera" on configuracoes for all to authenticated
  using ((auth.jwt() ->> 'email') = 'barbeariapb11@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'barbeariapb11@gmail.com');
