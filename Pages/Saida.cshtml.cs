using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using Xsports.Models;

namespace Xsports.Pages
{
    public class SaidaModel : PageModel
    {
        private readonly AppDbContext _context;

        public SaidaModel(AppDbContext context)
        {
            _context = context;
        }

        [BindProperty]
        public Movimentacao NovaSaida { get; set; } = new();

        // Lista de produtos
        public SelectList ListaProdutos { get; set; } = default!;

        public async Task<IActionResult> OnGetAsync()
        {
            await CarregarProdutosAsync();
            return Page();
        }

        public async Task<IActionResult> OnPostAsync()
        {
            var produto = await _context.Produtos.FindAsync(NovaSaida.ProdutoId);

            if (produto == null)
            {
                ModelState.AddModelError(string.Empty, "Produto não encontrado.");
                await CarregarProdutosAsync();
                return Page();
            }

            // Não permite dar saída em quantidade maior do que há no estoque
            if (NovaSaida.Quantidade > produto.Estoque)
            {
                ModelState.AddModelError("NovaSaida.Quantidade", $"Estoque insuficiente! Saldo atual: {produto.Estoque} unidades.");
                await CarregarProdutosAsync();
                return Page();
            }

            if (NovaSaida.Quantidade <= 0)
            {
                ModelState.AddModelError("NovaSaida.Quantidade", "A quantidade deve ser maior que zero.");
                await CarregarProdutosAsync();
                return Page();
            }

            // Abater do estoque do produto
            produto.Estoque -= NovaSaida.Quantidade;

            // Preencher a data e registrar a movimentação
            NovaSaida.DataMovimentacao = DateTime.Now;
            _context.Movimentacoes.Add(NovaSaida);

            // Salvar as duas alterações no Banco
            await _context.SaveChangesAsync();

            return RedirectToPage("/Estoque");
        }

        private async Task CarregarProdutosAsync()
        {
            var produtos = await _context.Produtos
                .OrderBy(p => p.Nome)
                .ToListAsync();

            ListaProdutos = new SelectList(produtos, "Id", "Nome");
        }
    }
}