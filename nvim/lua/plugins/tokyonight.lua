return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true, -- ГЛАВНАЯ НАСТРОЙКА: убирает фон редактора
      styles = {
        sidebars = "transparent", -- Делает дерево файлов (слева) тоже прозрачным
        floats = "transparent", -- Всплывающие окна (автодополнение/инфо).
        -- Совет: если текст будет плохо читаться, поменяйте "transparent" на "dark"
      },
    },
  },
}
