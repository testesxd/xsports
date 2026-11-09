using Microsoft.EntityFrameworkCore;
using Xsports.Models;

namespace Xsports.Pages
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options) { }

        public DbSet<Produto> Produtos { get; set; } = null!;
        public DbSet<Movimentacao> Movimentacoes { get; set; } = null!;
        public DbSet<Usuario> Usuarios { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Produtos
            modelBuilder.Entity<Produto>()
                .ToTable("produtos");

            // Movimentações
            modelBuilder.Entity<Movimentacao>()
                .ToTable("movimentacoes");

            // Usuários
            modelBuilder.Entity<Usuario>(entity =>
            {
                entity.ToTable("usuarios");

                entity.HasKey(usuario => usuario.Id);

                entity.Property(usuario => usuario.Id)
                    .HasColumnName("Id")
                    .ValueGeneratedOnAdd();

                entity.Property(usuario => usuario.Nome)
                    .HasColumnName("Nome")
                    .HasMaxLength(150)
                    .IsRequired();

                entity.Property(usuario => usuario.Email)
                    .HasColumnName("Email")
                    .HasMaxLength(255)
                    .IsRequired();

                entity.Property(usuario => usuario.SenhaHash)
                    .HasColumnName("SenhaHash")
                    .HasMaxLength(255)
                    .IsRequired();

                entity.Property(usuario => usuario.DataCadastro)
                    .HasColumnName("DataCadastro")
                    .HasColumnType("datetime(6)")
                    .HasDefaultValueSql("CURRENT_TIMESTAMP(6)");

                entity.HasIndex(usuario => usuario.Email)
                    .IsUnique()
                    .HasDatabaseName("IX_Usuarios_Email");
            });
        }
    }
}