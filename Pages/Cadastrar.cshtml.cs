using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Xsports.Pages
{
    public class CadastrarModel : PageModel
    {
        private readonly AppDbContext _context;
        private readonly IWebHostEnvironment _environment;

        // Banco de dados
        public CadastrarModel(AppDbContext context, IWebHostEnvironment environment)
        {
            _context = context;
            _environment = environment;
        }

        [BindProperty]
        public Produto NovoProduto { get; set; } = new();

        // Recebe o arquivo da imagem vindo do formulário
        [BindProperty]
        public IFormFile? Foto { get; set; }

        public void OnGet()
        {
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            // Lógica para salvar a foto na pasta 
            if (Foto != null && Foto.Length > 0)
            {
                string pastaUploads = Path.Combine(_environment.WebRootPath, "images");
                
                if (!Directory.Exists(pastaUploads))
                {
                    Directory.CreateDirectory(pastaUploads);
                }

                // Gera um nome único para o arquivo
                string nomeArquivo = Guid.NewGuid().ToString() + Path.GetExtension(Foto.FileName);
                string caminhoCompleto = Path.Combine(pastaUploads, nomeArquivo);

                using (var stream = new FileStream(caminhoCompleto, FileMode.Create))
                {
                    await Foto.CopyToAsync(stream);
                }

                // Salva o caminho da foto no objeto do produto
                NovoProduto.ImagemUrl = "/images/" + nomeArquivo;
            }

            // Salva o produto no banco MySQL
            _context.Produtos.Add(NovoProduto);
            await _context.SaveChangesAsync();

            // Redireciona para a tela de Estoque
            return RedirectToPage("/Estoque");
        }
    }
}