# ZnisBack Studio — instalação pelo celular

## O que vem neste projeto
- `index.html`: site completo, adaptado para celular.
- `version.json`: versão atual.
- `supabase_setup.sql`: tabelas, autenticação por perfil, regras de acesso e políticas de arquivos.
- `LEIA-ME.md`: este guia.

## 1. Criar o backend gratuito
1. Abra https://supabase.com no navegador do celular e crie um projeto.
2. Em **Authentication > Providers > Email**, mantenha Email/Password ativo e desative o cadastro público (Sign ups), se a opção estiver disponível no seu painel.
3. Em **Authentication > Users**, adicione dois usuários:
   - `znisback@znisback.app` — use a senha do znisback informada pelo proprietário.
   - `lnisback@znisback.app` — use a senha do lnisback informada pelo proprietário.
   Desative a confirmação de e-mail para essas contas internas, se o painel solicitar.
4. Abra **SQL Editor > New query**, cole todo o conteúdo de `supabase_setup.sql` e execute.
5. Em **Storage**, crie um bucket chamado `studio-files` e deixe **Public bucket desativado**.
6. Em **Project Settings > API**, copie o Project URL e a chave `anon`/`publishable` (nunca use `service_role` no site).

## 2. Conectar o HTML
1. Abra `index.html` no editor do GitHub.
2. No início do último bloco `<script>`, procure:
   `const SUPABASE_URL = "COLE_A_URL_DO_SUPABASE";`
   e substitua pelo Project URL.
3. Substitua `COLE_A_CHAVE_ANON_PUBLICA` pela chave anon/publishable do projeto.
4. Salve o arquivo.

## 3. Publicar no GitHub Pages
1. Crie um repositório GitHub chamado `znisback-studio` (ou use outro nome).
2. Envie `index.html` e `version.json` para a raiz do repositório.
3. Em **Settings > Pages**, escolha **Deploy from a branch**, selecione `main` e `/ (root)`, e salve.
4. Abra o endereço Pages gerado pelo GitHub.

## Como funciona
- Cada pessoa escolhe o próprio nome na tela inicial e entra com a senha correspondente.
- Arquivos são guardados no Storage privado do Supabase, não no GitHub nem apenas no celular.
- Depois do upload, o dono pode compartilhar com o outro usuário. O arquivo só aparece para o destinatário depois do compartilhamento.
- O chat é compartilhado entre as duas contas.
- A aba UPDT mantém o histórico de atualizações.

## Segurança importante
- O HTML contém apenas a chave pública `anon`/`publishable`, protegida pelas políticas RLS do SQL. Nunca cole uma chave `service_role` no HTML.
- Não coloque senhas no código. As senhas devem existir somente no cadastro de usuários do Supabase.
- Não compartilhe o Project URL/chave `service_role` publicamente.
- O acesso é limitado pelas contas cadastradas e pelas políticas do banco. Não habilite cadastro público.
- GitHub Pages é hospedagem estática; Supabase é necessário para login, arquivos e chat sincronizados entre aparelhos.

## Atualizações
Ao publicar uma nova versão, substitua `index.html` e atualize `version.json`. Registre as novidades, correções e melhorias na aba UPDT.
