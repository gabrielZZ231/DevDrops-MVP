# DevDrops MVP

MVP monolítico para compartilhamento de conhecimento técnico, desenvolvido com stack Java legado e empacotado para execução moderna com Docker.

## Por que este projeto importa

- Demonstra manutenção e evolução de aplicação legado corporativo.
- Combina compatibilidade com Java EE antigo e experiência de execução atual via containers.
- Inclui documentação arquitetural e automação de build/deploy.

## Stack técnica

- Java 7 (runtime legado)
- Java EE 5
- JBoss 5.1
- JSF 1.2 + Facelets
- JPA 1.0 (Hibernate)
- PostgreSQL
- Docker + Docker Compose

## Arquitetura

Aplicação em camadas (MVC):

- Apresentação: JSF/Facelets
- Aplicação: managed beans/controllers
- Persistência: DAO + JPA
- Domínio: entidades `Drop` e `Usuario`

DataSource JNDI utilizado pela aplicação: `java:/DevDropsDS`.

## Funcionalidades do MVP

- Publicar drops de conhecimento.
- Listar conteúdos publicados.
- Persistência em PostgreSQL com entidades relacionais.

## Diagramas (UML)

- Classes: `docs/uml/class-diagram.svg`
- Sequência (publicar drop): `docs/uml/sequence-publicar-drop.svg`
- Componentes: `docs/uml/components.svg`
- Deployment: `docs/uml/deployment.svg`

## Como rodar com Docker (recomendado)

### Pré-requisitos

- Docker Desktop instalado e ativo
- Porta `8080` livre

### 1) Configurar variáveis

Copie o exemplo e ajuste a senha do banco:

```bash
cp .env.example .env
```

No Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Depois edite `DEV_DROPS_DB_PASSWORD` no arquivo `.env`.

### 2) Subir aplicação + banco

```bash
docker compose up -d --build
```

### 3) Acessar aplicação

- URL: http://localhost:8080/devdrops/

### 4) Ver logs

```bash
docker compose logs -f app
```

```bash
docker compose logs -f db
```

### 5) Parar ambiente

```bash
docker compose down
```

Para remover também o volume do banco:

```bash
docker compose down -v
```

## Troubleshooting rápido (Docker)

- App não abre em `localhost:8080`:
  - Verifique status: `docker compose ps`
  - Aguarde o startup do JBoss (pode levar alguns segundos)
- Erro de autenticação no banco:
  - confira `DEV_DROPS_DB_USER` e `DEV_DROPS_DB_PASSWORD` no `.env`
  - reaplique: `docker compose up -d --build`
- Conflito de porta:
  - se `8080` estiver ocupada, pare o processo que está usando a porta

## Execução local legada (opcional)

Também é possível executar sem Docker com JBoss local e scripts em `scripts/`, mas para avaliação e demonstração a execução via Docker é o caminho recomendado.

## CI/CD

- CI: `.github/workflows/ci.yml`
- Release manual: `.github/workflows/release.yml`

## Segurança

- Segredos locais ficam no `.env` (ignorado no Git).
- Não publique credenciais reais em commits ou issues.
