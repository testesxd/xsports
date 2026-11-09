using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace Xsports.Pages
{
    public class EstoqueModel : PageModel
    {
        private readonly AppDbContext _context;

        public EstoqueModel(AppDbContext context)
        {
            _context = context;
        }

        public List<Produto> Produtos { get; set; } = new();

        [BindProperty(SupportsGet = true)]
        public string? TermoBusca { get; set; }

        public async Task OnGetAsync()
        {
            var query = _context.Produtos.AsQueryable();

            if (!string.IsNullOrWhiteSpace(TermoBusca))
            {
                query = query.Where(p => p.Nome.ToLower().Contains(TermoBusca.ToLower()));
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

        // Para retornar a quantidade de alertas baseada no estoque
        public async Task<IActionResult> OnGetNotificacoesAsync()
        {
            var totalAlertas = await _context.Produtos
                .Where(p => p.Estoque <= 10) // 10 ou menos já entra em Estoque Baixo ou Crítico
                .CountAsync();

            return new JsonResult(new { total = totalAlertas });
        }
    }
}