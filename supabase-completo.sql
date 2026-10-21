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


-- ===== PARTE 2: serviços, horários, bloqueios =====
-- Rode no Supabase: SQL Editor > New query > cole TUDO > Run
-- Pode rodar mais de uma vez sem dar erro.

alter table configuracoes add column if not exists passo int not null default 30;

create table if not exists servicos (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  preco numeric(8,2) not null,
  dur int not null,
  ativo boolean not null default true,
  ordem int not null default 0
);
create table if not exists horarios_semana (
  dia int primary key check (dia between 0 and 6),
  aberto boolean not null default true,
  abre time not null default '09:00',
  fecha time not null default '19:00'
);
create table if not exists bloqueios (
  id uuid primary key default gen_random_uuid(),
  data date not null,
  inicio time,
  fim time,
  motivo text not null default ''
);

alter table servicos enable row level security;
alter table horarios_semana enable row level security;
alter table bloqueios enable row level security;

do $$
declare t text;
begin
  foreach t in array array['servicos','horarios_semana','bloqueios'] loop
    execute format('drop policy if exists "todos leem" on %I', t);
    execute format('create policy "todos leem" on %I for select to anon, authenticated using (true)', t);
    execute format('drop policy if exists "profissional altera" on %I', t);
    execute format($p$create policy "profissional altera" on %I for all to authenticated
      using ((auth.jwt() ->> 'email') = 'barbeariapb11@gmail.com')
      with check ((auth.jwt() ->> 'email') = 'barbeariapb11@gmail.com')$p$, t);
  end loop;
end $$;

insert into horarios_semana (dia, aberto) values (0,false),(1,true),(2,true),(3,true),(4,true),(5,true),(6,true)
  on conflict (dia) do nothing;

insert into servicos (nome, preco, dur, ordem)
select * from (values ('Corte',35,30,1),('Barba',25,30,2),('Sobrancelha',10,15,3),('Pigmentação',30,30,4)) v(nome,preco,dur,ordem)
where not exists (select 1 from servicos);
