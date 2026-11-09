using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Xsports.Models;

namespace Xsports.Pages
{
    public class MovimentacoesModel : PageModel
    {
        private readonly AppDbContext _context;

        public MovimentacoesModel(AppDbContext context)
        {
            _context = context;
        }

        [BindProperty]
        public Movimentacao NovaMovimentacao { get; set; } = new();

        public List<Movimentacao> HistoricoMovimentacoes { get; set; } = new();
        public List<Produto> ProdutosDisponiveis { get; set; } = new();

        [BindProperty(SupportsGet = true)]
        public string? TermoBusca { get; set; }

        // Guardar a mensagem de sucesso
        [TempData]
        public string? MensagemSucesso { get; set; }
        
        public async Task OnGetAsync()
        {
            ProdutosDisponiveis = await _context.Produtos
                .Where(p => p.Estoque > 0)
                .OrderBy(p => p.Nome)
                .ToListAsync();

            var query = _context.Movimentacoes
                .Include(m => m.Produto)
                .OrderByDescending(m => m.DataMovimentacao)
                .AsQueryable();

            if (!string.IsNullOrEmpty(TermoBusca))
            {
                query = query.Where(m => m.Produto!.Nome.Contains(TermoBusca) || m.Motivo.Contains(TermoBusca));
            }

            HistoricoMovimentacoes = await query.ToListAsync();
        }

        public async Task<IActionResult> OnPostAsync()
        {
            var produto = await _context.Produtos.FindAsync(NovaMovimentacao.ProdutoId);

            if (produto == null)
            {
                ModelState.AddModelError("", "Produto não encontrado.");
            }
            else if (produto.Estoque < NovaMovimentacao.Quantidade)
            {
                ModelState.AddModelError("", $"Estoque insuficiente. Quantidade disponível: {produto.Estoque}.");
            }

            if (!ModelState.IsValid)
            {
                ProdutosDisponiveis = await _context.Produtos.Where(p => p.Estoque > 0).ToListAsync();
                HistoricoMovimentacoes = await _context.Movimentacoes
                    .Include(m => m.Produto)
                    .OrderByDescending(m => m.DataMovimentacao)
                    .ToListAsync();
                return Page();
            }

            // Abater a quantidade no estoque do produto
            produto!.Estoque -= NovaMovimentacao.Quantidade;

            // Registrar o histórico da movimentação 
            NovaMovimentacao.DataMovimentacao = DateTime.Now;
            _context.Movimentacoes.Add(NovaMovimentacao);

            await _context.SaveChangesAsync();

            // Mensagem que será exibida 
            MensagemSucesso = $"Saída de {NovaMovimentacao.Quantidade} unidade(s) do produto '{produto.Nome}' registrada com sucesso!";
            
            return RedirectToPage("/Movimentacoes");
        }
    }
}