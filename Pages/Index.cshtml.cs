using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;

namespace Xsports.Pages
{
    public class Produto
    {
        public int Id { get; set; }
        public string Nome { get; set; } = string.Empty;
        [Range(typeof(decimal), "0.01", "79228162514264337593543950335", ErrorMessage = "O preço deve ser maior que zero.")]
        public decimal Preco { get; set; }
        [Range(0, int.MaxValue, ErrorMessage = "A quantidade em estoque não pode ser negativa.")]
        public int Estoque { get; set; }
        public string ImagemUrl { get; set; } = string.Empty;

       public string Categoria {get; set;} = "Masculino"; // Opções: Masculino, Feminino e Infantil
    }

    public class IndexModel : PageModel
    {
        private readonly AppDbContext _context;

        public IndexModel(AppDbContext context)
        {
            _context = context;
        }

        public List<Produto> Produtos { get; set; } = new();

        [BindProperty(SupportsGet = true)]
        public string? TermoBusca { get; set; }

        // Busca por Categoria
        [BindProperty(SupportsGet = true)]
        public string? Categoria { get; set; }

        public async Task OnGetAsync()
        {
            var query = _context.Produtos.AsQueryable();

            // Filtro por Categoria
            if (!string.IsNullOrEmpty(Categoria))
            {
                if (Categoria == "Masculino" || Categoria == "Feminino")
                {
                    query = query.Where(p => p.Categoria == Categoria || p.Categoria == "Unissex");
                }
                else
                {
                    query = query.Where(p=> p.Categoria == Categoria);
                }
            }

            // Se o usuário digitou algo na busca da Home, filtra por nome
            if (!string.IsNullOrEmpty(TermoBusca))
            {
                query = query.Where(p => p.Nome.Contains(TermoBusca));
            }

            Produtos = await query.ToListAsync();
        }

        public async Task<IActionResult> OnPostDeletarAsync(int id)
        {
            var produto = await _context.Produtos.FindAsync(id);

            if (produto != null)
            {
                _context.Produtos.Remove(produto);
                await _context.SaveChangesAsync();
            }

            return RedirectToPage();
        }
    }

    
}