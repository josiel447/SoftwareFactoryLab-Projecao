create type user_group as enum (
    'client', 'admin', 'professional'
);

create table users (
    id INT generated always as identity primary key,
    email TEXT unique not null,
    
    role user_group 
);

create type collection_type as enum (
	'publication', 'exercise', 'analise', 'storage'
);


create table collection (
    id INT generated always as identity primary key,
    description TEXT, -- breve descricao por parte do usuario sobre o momento em que tirou/gravou os arquivos 
    type collection_type,
    
    client_id INT references users(id)
);

create type media_type as enum (
    'image', 'video'
);

create table media (
    id INT generated always as identity primary key,
    path VARCHAR(1024), -- caminho em que o arquivo real estará guardado em formato blob
    type media_type, 
    
    collection_id INT references collection(id) -- refenciando o grupo do arquivo
);

create table diagnostic ( -- diagnostico gerado a partir da colecao de analises 
    id INT generated always as identity primary key,
    weight numeric(10,2), -- peso
    fat numeric(10,2), -- gordura corporal
    lean_mass numeric(10,2), -- massa magra
    symmetry numeric(10,2), 
    description TEXT,
    
    client_id INT references users(id),
    profession_id INT references users(id)
);

create table analysis ( -- analise unitaria de cada imagem/video 
    id INT generated always as identity primary key,
    pose VARCHAR, -- maybe can be ENUM
    landmark TEXT, -- pontos de referencia gerados pela IA (se necessário)
    proportions TEXT, -- proporcoes do corpo
    confidence float, -- precisao nas analises
    description TEXT,
    
    media_id INT references media(id),
    diagnostic_id INT references diagnostic(id)
);

create table progress ( -- timeline dos diagnosticos \ evolucao do usuario
    id INT generated always as identity primary key,
    fat_difference numeric(10,2), 
    muscle_mass_difference numeric(10,2),
    date_interval int,
    
    user_id INT references users(id),
    current_diag_id INT references diagnostic(id),
    previous_diag_id INT references diagnostic(id)
);

-- ============================================================
-- =================== notification schema ====================
-- ============================================================

create type notification_type as enum (
	'INFO', 'WARNING', 'ERROR'
);

create table notification (
	id INT generated always as identity primary key,
	title VARCHAR(255),
	message TEXT not null,
	type notification_type,
	
	user_id INT references users(id) 
);

create table recipient_notification (
	id INT generated always as identity primary key,
	read_at TIMESTAMP null,
	
	user_id INT references users(id),
	notification_id INT references notification(id)
);

create type channel_type as enum (
	'SYSTEM', 'EMAIL'
);

create type status_delivery as enum (
	'PENDING', 'FAILED', 'SENT'
);

create table notification_delivery (
	id INT generated always as identity primary key,
	channel channel_type,
	status status_delivery,
	
	recipient_id INT references recipient_notification(id)
);


-- ============================================================
-- =================== subscription schema ====================
-- ============================================================

create type plan_type as enum (
	'Individual', 'Duo', 'Family'
);

create table plan (
	id INT generated always as identity primary key,
	name plan_type,
	price numeric(12, 2),
	vality_acess int default 30, -- quantos dias de acesso o usuario terá de acesso ao assinar o plano
	credits_acess int -- quantidade de vezes que ele poderá utilizar a funcao principal (a ser revisado)
);

create table subscription (
	id INT generated always as identity primary key,
	periods_paid INT, -- quantidade de periodos que o usuario pagou pelo plano, ex: 1 igual a 30 dias, 2 igual a pagou pela validade do plano duas vezes 60 dias...
	
	user_id INT references users(id),
	plan_id INT references plan(id)
);

 create type payment_type as enum (
   'PIX', 'CREDIT', 'DEBIT'
);

create type transaction_status as enum (
   'PROCESSING', 'PROCESSED', 'FAILED'
);

create table transaction ( 
    id INT generated always as identity primary key,
    payment_method payment_type,
    status transaction_status,
        
    subscription_id INT references subscription(id) -- informacoes sobre o plano e o usuario estão diretamente na inscricao
);

        
-- ============================================================
-- =================== spreadsheet schema =====================
-- ============================================================

create type exercise_type as enum (
	'leg', 'arm', 'back'
);

create table exercise (
	id INT generated always as identity primary key,
	description TEXT,
	type exercise_type,

	collection_id INT references collection(id)
);

create table execution (
	id INT generated always as identity primary key,
	description TEXT,
	repetition INT,
	series INT,
	
	exercise_id INT references exercise(id)
);

create type daily_type as enum (
	'leg', 'arm', 'back'
);

create table daily (
	id INT generated always as identity primary key,
	description TEXT,
	type daily_type
);

create table daily_execution (
	daily_id INT references daily(id),
	execution_id INT references execution(id),
	step_suggestion INT
);

create type spreadsheet_type as enum (
	'generic', 'personal'
);

create table spreadsheet (
	id INT generated always as identity primary key,
	description TEXT,
	type spreadsheet_type
);

create table spreadsheet_daily (
	spreadsheet_id INT references spreadsheet(id),
	daily_id INT references daily(id),
	weekday INT
);


create table user_spreadsheet(
	user_id INT references users(id),
	spreadsheet_id INT references spreadsheet(id),
	started_in DATE,
	ended_in DATE
);