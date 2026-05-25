# Documento Técnico: Milton Fit Delas

Este documento define a especificação técnica e a arquitetura de infraestrutura da Smart Fitness Platform, uma solução nativa na cloud projetada para escalabilidade extrema, automação via Inteligência Artificial e conformidade rigorosa com segurança de dados.

## 1. Visão Geral da Arquitetura e Atores

A plataforma utiliza uma arquitetura de microserviços desacoplada, permitindo evolução independente dos módulos de negócio e do motor de IA. O sistema foi concebido para suportar alta carga de uploads de mídia e processamento assíncrono.

**Atores e Interfaces de Acesso:**

- **Aluno:** Interface **Mobile (Ionic 8 + Angular 21)**. Responsável pelo registro de treinos, upload de fotos/vídeos de evolução e consumo de métricas de saúde.
- **Personal Trainer:** Interface **Web (Angular 21)**. Atua na criação de fichas personalizadas, realização de anamneses técnicas e avaliação de vídeos de execução.
- **Administrador:** Interface **Web (Angular 21)**. Gere planos de subscrição, moderação de conteúdo e monitorização global via **Spring Boot Actuator**.
- **Sistema de IA:** Microserviço **Python (FastAPI)**. Realiza visão computacional para análise de postura e predição de tendências, operando como um consumidor de eventos.

## 2. Stack Tecnológica e Requisitos Não Funcionais (RNF)

Requisito

Tecnologia / Estratégia de Implementação

**RNF01 – Backend Core**

Java 21+ / Spring Boot 4.0.6 (Oakwood)

**RNF02 – Motor de IA**

Python 3.12+ / FastAPI / TensorFlow / OpenCV

**RNF03 – Frontend Multiplataforma**

Angular 21 (Web) e Ionic 8 (Mobile)

**RNF04 – Persistência de Mídia**

AWS S3 com Criptografia Server-Side (SSE)

**RNF05 – Escalabilidade**

Spring Cloud 2025.1.1 (Oakwood) / Kubernetes

**RNF06 – Resiliência**

Circuit Breaker (Resilience4j) / Spring Cloud Gateway

**RNF07 – Mensageria**

RabbitMQ com Quorum Queues (Garantia de Entrega)

**RNF08 – Cache Distribuído**

Redis (Redução de latência para RF03 e RF04)

**RNF09 – Segurança/Auth**

Spring Security 7 / RBAC / JWT

**RNF10 – Conformidade (LGPD)**

URLs Assinadas (S3) / Isolamento de PII

**RNF11 – Hardening**

Docker Hardened Images (Distroless / Non-root)

## 3. Arquitetura de Microserviços, Roteamento e Resiliência

O ecossistema é orquestrado pelo **Spring Cloud Gateway**, que atua como um micro-proxy inteligente, aplicando filtros de segurança e limites de taxa (Rate Limiting) baseados no plano do utilizador (RF26-RF28).

**Comunicação Híbrida e Confiabilidade:**

1. **Síncrona (REST/HTTPS):** Operações CRUD, autenticação e consultas rápidas. Implementa o padrão **Circuit Breaker** via Spring Cloud Circuit Breaker (Resilience4j). Caso o serviço de IA ou de Mídia apresente timeout, o Gateway redireciona para um *fallback* estático ou resposta em cache.
2. **Assíncrona (RabbitMQ):** Processamento de vídeos pesados. São utilizadas **Quorum Queues** para assegurar que os metadados dos vídeos não se percam em caso de falha de um nó do broker.
3. **Gestão de SLA (RNF07):** Para o plano **Premium Plus**, mensagens de feedback são publicadas em filas de prioridade, garantindo o processamento e retorno dentro da janela de 72 horas.

## 4. Estratégia de Persistência Poliglota

A escolha das bases de dados baseia-se na natureza do dado e na garantia de consistência necessária para cada funcionalidade.

Entidade / Domínio

Base de Dados

Justificativa Técnica

Usuários, Planos, Anamnese (RF14)

**PostgreSQL**

Integridade ACID e relacionamentos complexos.

Medidas (RF05), Métricas (RF19)

**MongoDB**

Dados de séries temporais e metadados flexíveis.

Biblioteca (RF03), Gasto Calórico

**Redis**

Cache de alta performance para dados de leitura intensiva.

MediaRegistry (Metadados S3)

**PostgreSQL**

Controle de status (PENDING, PROCESSED) e auditoria.

Arquivos de Vídeo/Imagem

**AWS S3**

Armazenamento de objetos escalável com expiração automática.

## 5. Inteligência Artificial e Fluxo Crítico de Mídia

O microserviço de IA é isolado em Python para aproveitar as otimizações nativas de processamento tensorial.

**Fluxo Crítico de Análise Assíncrona:**

1. O Aluno inicia o upload via Mobile; o Backend gera uma **URL Assinada (Presigned URL)** do S3.
2. O Mobile faz o upload direto para o S3, reduzindo a carga no microserviço de Backend.
3. Após o upload, o Backend insere o registro na tabela `MediaRegistry` e publica um evento no **RabbitMQ** (Quorum Queue).
4. O serviço **FastAPI** consome a tarefa, processa o vídeo via **OpenCV/TensorFlow** e armazena os resultados de postura (RF07) e simetria (RF08).
5. O status é atualizado via Webhook ou WebSocket para o Personal Trainer e o Aluno.

*Nota: A predição de Churn (RF11) foi movida para o backlog pós-MVP para priorizar a acurácia da análise visual.*

## 6. Segurança e Hardening de Infraestrutura

**Autenticação e Autorização:** Implementação via **Spring Security 7**. O controle de acesso (RBAC) é validado no Gateway, onde os filtros verificam se o plano do aluno permite a funcionalidade solicitada (ex: bloqueio de upload de vídeo para Plano Basic - RF26).

**Proteção de Dados (LGPD):**

- **Criptografia:** Todos os dados sensíveis são criptografados em repouso. O bucket S3 utiliza SSE-S3.
- **Privacidade:** Fotos de evolução nunca possuem URLs públicas. O acesso é restrito a URLs assinadas com expiração de 300 segundos.

**Hardening de Contentores:** Conforme as diretrizes do **Docker Docs**, as imagens de produção devem ser:

- **Distroless:** Para remover shells e utilitários desnecessários, minimizando a superfície de ataque.
- **Non-root User:** Os processos dentro do contentor nunca rodam como `root`.
- **Sandboxing:** Uso de isolamento de rede entre o microserviço de IA e o banco de dados relacional.

## 7. Estrutura do Projeto e Dependências

### Estrutura de Pastas

```
smartfitness-root/
├── infrastructure/              # Terraform, K8s manifests
├── docker-compose.yml           # Local orchestration (Postgres, Mongo, Redis, Rabbit)
├── smartfitness-backend/        # Spring Boot 4.0.6
│   ├── src/main/java/           # DDD Layers
│   └── pom.xml
└── smartfitness-ai-service/     # FastAPI
    ├── app/                     # AI Models & Processing Logic
    ├── requirements.txt
    └── Dockerfile               # Hardened Python Image

```

### Dependências Essenciais

**Backend (pom.xml):**

```
<dependencies>
    <dependency>org.springframework.cloud:spring-cloud-starter-gateway</dependency>
    <dependency>org.springframework.cloud:spring-cloud-starter-circuitbreaker-resilience4j</dependency>
    <dependency>org.springframework.boot:spring-boot-starter-data-jpa</dependency> <!-- Postgres -->
    <dependency>org.springframework.boot:spring-boot-starter-data-mongodb</dependency>
    <dependency>org.springframework.boot:spring-boot-starter-data-redis</dependency>
    <dependency>org.springframework.boot:spring-boot-starter-amqp</dependency> <!-- RabbitMQ -->
    <dependency>org.springframework.boot:spring-boot-starter-actuator</dependency> <!-- Monitoring -->
    <dependency>org.springframework.boot:spring-boot-starter-security</dependency>
</dependencies>

```

**IA Service (requirements.txt):**

```
fastapi[standard]
uvicorn
opencv-python-headless
tensorflow
pydantic
aiobotocore  # Async S3 Access
python-multipart # Form-data handling

```

## 8. Escopo do MVP e Limitações

A primeira entrega foca na estabilidade do núcleo de gestão e na validação da IA.

- [x] Cadastro, Autenticação e RBAC (Spring Security 7).
- [x] Gestão de Treinos e Fichas Personalizadas (RF13).
- [x] Persistência de Anamnese e Medidas Corporais (RF14, RF05).
- [x] Integração S3 com URLs Assinadas para Evolução (RF05).
- [x] IA Básica: Análise de postura e simetria em **imagens estáticas**.
- [x] Biblioteca de Exercícios com Cache (Redis).

**Limitações do MVP:**

- A análise de IA em vídeos de execução (RF16) e o ajuste dinâmico automático (RF10) estão previstos para a V2.
- **RF11 (Predição de Churn)** está desativado no MVP para coleta de dados de treino iniciais.