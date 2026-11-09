using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace Xsports.Pages
{
    public class ConfiguracoesModel : PageModel
    {
        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _environment;

        public ConfiguracoesModel(IConfiguration configuration, IWebHostEnvironment environment)
        {
            _configuration = configuration;
            _environment = environment;
        }

        [BindProperty]
        public string NomeLoja { get; set; } = string.Empty;

        [BindProperty]
        public string Desenvolvedores { get; set; } = string.Empty;

        public void OnGet()
        {
            NomeLoja = _configuration["ConfiguracoesLoja:NomeLoja"] ?? "Xsports";
            Desenvolvedores = _configuration["ConfiguracoesLoja:Desenvolvedores"] ?? "Desenvolvedores do Projeto";
        }

        public IActionResult OnPost()
        {
            if (string.IsNullOrWhiteSpace(NomeLoja))
            {
                return Page();
            }

            try
            {
                string caminhoAppsettings = Path.Combine(_environment.ContentRootPath, "appsettings.json");

                if (System.IO.File.Exists(caminhoAppsettings))
                {
                    string jsonString = System.IO.File.ReadAllText(caminhoAppsettings);
                    var jsonNode = JsonNode.Parse(jsonString);

                    if (jsonNode != null)
                    {
                        if (jsonNode["ConfiguracoesLoja"] == null)
                        {
                            jsonNode["ConfiguracoesLoja"] = new JsonObject();
                        }

                        jsonNode["ConfiguracoesLoja"]!["NomeLoja"] = NomeLoja;
                        jsonNode["ConfiguracoesLoja"]!["Desenvolvedores"] = Desenvolvedores;

                        var options = new JsonSerializerOptions { WriteIndented = true };
                        System.IO.File.WriteAllText(caminhoAppsettings, jsonNode.ToJsonString(options));
                    }
                }

                TempData["MensagemSucesso"] = "Configurações salvas com sucesso!";
            }
            catch (Exception ex)
            {
                // Mensagem de erro
                ModelState.AddModelError(string.Empty, "Erro ao salvar as configurações: " + ex.Message);
                return Page();
            }

            return RedirectToPage();
        }
    }
}