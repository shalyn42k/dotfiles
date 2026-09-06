function fish_greeting
    # Явный -c: имя по умолчанию (config.jsonc) принадлежит matugen'у шелла
    # serpantinum, который переписывает его на каждую смену обоев. Наш баннер
    # рендерит dotprofile в rig.jsonc — см. комментарий там.
    fastfetch -c ~/.config/fastfetch/rig.jsonc --key-padding-left 5
end
