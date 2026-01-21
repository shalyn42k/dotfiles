return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        qmlls = {
          -- Команда запуска
          cmd = { "/usr/lib/qt6/bin/qmlls" },

          -- Переменная для Arch Linux, чтобы видеть модули Qt
          cmd_env = {
            QML_IMPORT_PATH = "/usr/lib/qt6/qml",
          },

          filetypes = { "qml", "qmljs" },

          -- Включаем поддержку одиночных файлов
          single_file_support = true,

          -- Логика поиска корня проекта
          root_dir = function(fname)
            local util = require("lspconfig.util")
            -- Ищем .git или qmldir, если нет — берем текущую папку через vim.uv.cwd()
            return util.root_pattern("qmldir", ".git")(fname) or vim.uv.cwd()
          end,
        },
      },
    },
  },

  -- Настройка форматтера
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        qml = { "qmlformat" },
        qmljs = { "qmlformat" },
      },
      formatters = {
        qmlformat = {
          command = "/usr/lib/qt6/bin/qmlformat",
        },
      },
    },
  },
}
