# LA BARRE D'OUTILS — posee SUR la zone de travail, et translucide au repos.
#
# Elle laisse voir le guide a travers elle : c'est ce qui donne au logiciel son air de
# calque plutot que de panneau. Mais on ne travaille pas a travers une vitre : des que le
# curseur entre, elle redevient pleine.
#
# ⚠ ON TEINTE `self_modulate`, PAS `modulate`. Le premier ne touche que le fond dessine par
# ce noeud ; le second aurait delave le texte et les boutons avec lui, et une barre dont on
# ne lit plus les libelles n'est pas jolie, elle est cassee.
extends PanelContainer

## Opacite du fond quand le curseur est ailleurs.
const RESTING: float = 0.62

## Vitesse du fondu, en unites d'opacite par seconde. Assez vif pour suivre la main, assez
## lent pour qu'on voie que c'est voulu.
const FADE_SPEED: float = 6.0


func _ready() -> void:
	self_modulate.a = RESTING


## ⚠ ON TESTE LE RECTANGLE, PAS `mouse_entered`. Le signal se declenche a l'envers des qu'on
## passe sur un enfant : entrer dans un bouton fait « sortir » du panneau, et la barre
## clignoterait a chaque survol.
func _process(delta: float) -> void:
	var inside: bool = get_global_rect().has_point(get_global_mouse_position())
	self_modulate.a = move_toward(self_modulate.a, 1.0 if inside else RESTING, FADE_SPEED * delta)
