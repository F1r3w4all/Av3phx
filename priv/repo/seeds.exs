# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     RideFastApi.Repo.insert!(%RideFastApi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias RideFastApi.Repo
alias RideFastApi.Accounts.Language

alias RideFastApi.Repo
alias RideFastApi.Accounts.Language

Repo.insert!(%Language{
  name: "Português (Brasil)",
  code: "pt-BR",

  name: "Inglês",
  code: "en"# <- preenche o campo obrigatório
})
