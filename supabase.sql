-- Rode no Supabase: SQL Editor > New query > Run
-- ANTES: troque SEU_EMAIL_AQUI pelo e-mail do único profissional (2 vezes).

create table agendamentos (
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

-- Cliente (sem login): só pode CRIAR agendamento. Não consegue ler nada.
create policy "cliente cria" on agendamentos for insert to anon
  with check (status = 'agendado');

-- Profissional: só o e-mail abaixo vê, edita e apaga tudo.
create policy "profissional total" on agendamentos for all to authenticated
  using ((auth.jwt() ->> 'email') = 'SEU_EMAIL_AQUI')
  with check ((auth.jwt() ->> 'email') = 'SEU_EMAIL_AQUI');

-- Cliente vê apenas horários ocupados (sem nome nem telefone).
create function horarios_ocupados(dia date)
returns table(hora time, duracao_min int)
language sql security definer set search_path = public as $$
  select hora, duracao_min from agendamentos where data = dia and status <> 'cancelado'
$$;
grant execute on function horarios_ocupados(date) to anon, authenticated;

-- Impede dois agendamentos no mesmo horário.
create function checa_conflito() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from agendamentos a
    where a.data = new.data and a.status <> 'cancelado'
      and new.hora < a.hora + make_interval(mins => a.duracao_min)
      and a.hora < new.hora + make_interval(mins => new.duracao_min))
  then raise exception 'Horário indisponível'; end if;
  return new;
end $$;
create trigger trg_conflito before insert on agendamentos
  for each row execute function checa_conflito();

-- ===== PARTE 2: WhatsApp do profissional =====
-- Se você já rodou a parte 1, rode somente daqui para baixo.
create table configuracoes (
  id int primary key default 1 check (id = 1),
  whatsapp text not null default ''
);
insert into configuracoes (id) values (1);
alter table configuracoes enable row level security;

-- O número do WhatsApp precisa ser público (o cliente envia a mensagem para ele).
create policy "todos leem" on configuracoes for select to anon, authenticated using (true);

-- Só o profissional altera. (Troque SEU_EMAIL_AQUI pelo mesmo e-mail de antes.)
create policy "profissional altera" on configuracoes for all to authenticated
  using ((auth.jwt() ->> 'email') = 'SEU_EMAIL_AQUI')
  with check ((auth.jwt() ->> 'email') = 'SEU_EMAIL_AQUI');
