using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Xsports.Models;

namespace Xsports.Pages
{
    public class AlertasModel : PageModel
    {
        private readonly AppDbContext _context; 

        public AlertasModel(AppDbContext context)
        {
            _context = context;
        }

        public List<Produto> ProdutosAlerta {get; set;} = new();

        public async Task OnGetAsync()
        {
            // Busca apenas os produtos com estoque menor ou igual a 10 (baixo ou crítico)
            ProdutosAlerta = await _context.Produtos
                .Where(p => p.Estoque <= 10)
                .OrderBy(p => p.Estoque)
                .ToListAsync();
        }
    }
}