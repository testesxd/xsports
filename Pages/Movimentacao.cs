using System.ComponentModel.DataAnnotations;
using Xsports.Pages;

namespace Xsports.Models
{
    public class Movimentacao
    {
        public int Id {get; set;}

        [Required]
        public int ProdutoId {get; set;}
        public Produto? Produto {get; set;}

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "A quantidade deve ser maior que zero.")]
        public int Quantidade {get; set;}

        [Required]
        public string Motivo {get; set;} = "Venda"; // Ex: Venda, Perda, Uso Interno
        public string? Observacao {get; set;}
        public DateTime DataMovimentacao {get; set;} = DateTime.Now;

    }
}