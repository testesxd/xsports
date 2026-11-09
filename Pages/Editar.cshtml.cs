using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Xsports.Pages
{
    public class EditarModel : PageModel
    {
        private readonly AppDbContext _context;
        private readonly IWebHostEnvironment _environment;

        public EditarModel(AppDbContext context, IWebHostEnvironment environment)
        {
            _context = context;
            _environment = environment;
        }

        [BindProperty]
        public Produto Produto { get; set; } = new();

        [BindProperty]
        public IFormFile? NovaFoto { get; set; }

        public async Task<IActionResult> OnGetAsync(int id)
        {
            var produtoDoBanco = await _context.Produtos.FindAsync(id);

            if (produtoDoBanco == null)
            {
                return RedirectToPage("/Index");
            }

            Produto = produtoDoBanco;
            return Page();
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            var produtoDoBanco = await _context.Produtos.FindAsync(Produto.Id);

            if (produtoDoBanco == null)
            {
                return RedirectToPage("/Index");
            }

            // Se o usuário enviou uma nova foto, salva e atualiza a URL
            if (NovaFoto != null && NovaFoto.Length > 0)
            {
                string pastaUploads = Path.Combine(_environment.WebRootPath, "images");
                if (!Directory.Exists(pastaUploads))
                {
                    Directory.CreateDirectory(pastaUploads);
                }

                string nomeArquivo = Guid.NewGuid().ToString() + Path.GetExtension(NovaFoto.FileName);
                string caminhoCompleto = Path.Combine(pastaUploads, nomeArquivo);

                using (var stream = new FileStream(caminhoCompleto, FileMode.Create))
                {
                    await NovaFoto.CopyToAsync(stream);
                }

                produtoDoBanco.ImagemUrl = "/images/" + nomeArquivo;
            }

            // Atualiza as outras propriedades
            produtoDoBanco.Nome = Produto.Nome;
            produtoDoBanco.Preco = Produto.Preco;
            produtoDoBanco.Estoque = Produto.Estoque;
            produtoDoBanco.Categoria = Produto.Categoria;

            await _context.SaveChangesAsync();

            return RedirectToPage("/Index");
        }
    }
}