#!/usr/bin/tclsh

package require Tcl 8.5
package require math

proc set_property {dictionary key value} {
    global $dictionary
    array set $dictionary [list $key $value]
}

proc get_property {dictionary key} {
    global $dictionary
    return [lindex [array get $dictionary $key] 1]
}

proc incr_property {dictionary key} {
	set value [get_property $dictionary $key]
	incr value
	set_property $dictionary $key $value
}

proc usage {} {
	puts "poker.tcl [--num-players num] [--player-position pos] [--iterations iterations]"
	error {} 1
}

set num_players 8
set player_position 0
set iterations 1

proc parse_args {} {
	global argc
	global argv
	global num_players
	global player_position
	global iterations
	
	if {$argc > 3} {
		usage
	}
	
	for {set i 0} {$i < $argc} {incr i} {
		set arg [lindex $argv $i]
		switch -exact $arg {
			"--num-players" {
				incr i
				set num_players [lindex $argv $i]
			}
			"--player_position" {
				incr i
				set player_position [lindex $argv $i]
			}
			"--iterations" {
				incr i
				set iterations [lindex $argv $i]
			}
			default {
				puts stderr "Unknown arg $arg"
				usage
			}
		}
	}
}

set suits "S D H C"
set ranks "A K Q J T 9 8 7 6 5 4 3 2"
for {set i 14; set r 0} {$i > 1} {incr i -1; incr r} {
	set rank [lindex $ranks $r]
	set_property $rank "value" $i
}

set cards []
foreach rank $ranks {
	foreach suit $suits {
		lappend cards "$rank$suit"
	}
}

proc shuffle_cards {cards} {
	set new_cards {}
	set len [llength $cards]
	while {$len > 0} {
		set num [math::random [expr $len - 1]]
		set card [lindex $cards $num]
		set cards [lreplace $cards $num $num]
		lappend new_cards $card
		set len [llength $cards]
	}
	return $new_cards
}

proc process_cards {cards} {
	global num_players
	
	foreach card_num {0 1} {
		for {set i 0} {$i < $num_players} {incr i} {
			set card [lindex $cards 0]
			set cards [lreplace $cards 0 0]
			set_property "player$i" "card$card_num" $card
		}
	}
	
	# flop (3 cards)
	foreach card_num {0 1 2} {
		set card [lindex $cards 0]
		set cards [lreplace $cards 0 0]
		set_property "flop" "card$card_num" $card
	}
	
	# turn
	set card [lindex $cards 0]
	set cards [lreplace $cards 0 0]
	set_property "turn" "card" $card
	
	# river
	set card [lindex $cards 0]
	set cards [lreplace $cards 0 0]
	set_property "river" "card" $card
	
}

proc card_rank_value card {
	set rank_string [string range $card 0 0]
	return [get_property $rank_string "value"]
}

proc card_suit card {
	return [string range $card 1 1]
}

proc compare_ranks {a b} {
	set a_value [card_rank_value $a]
	set b_value [card_rank_value $b]
	if {$a_value < $b_value} {
		return -1
	} elseif {$a_value > $b_value} {
		return 1
	} else {
		return 0
	}
}

proc sort_cards_by_rank {cards} {
	set cards [lsort -decreasing -command compare_ranks $cards]
	return $cards
}

proc compare_suits {a b} {
	set a_suit [card_suit $a]
	set b_suit [card_suit $b]
	return [string compare $a_suit $b_suit]
}

proc sort_cards_by_suit {cards} {
	set cards [lsort -command compare_suits $cards]
	return $cards
}

# returns the first n cards, determined by hand, flop, turn and river.

proc get_player_hand {player {num_cards 7}} {
	set cards {}
	if {$num_cards > 0} {
		set card [get_property "player$player" "card0"]
		lappend cards $card
	}
	if {$num_cards > 1} {
		set card [get_property "player$player" "card1"]
		lappend cards $card
	}
	if {$num_cards > 2} {
		set card [get_property "flop" "card0"]
		lappend cards $card	
	}
	if {$num_cards > 3} {
		set card [get_property "flop" "card1"]
		lappend cards $card	
	}
	if {$num_cards > 4} {
		set card [get_property "flop" "card2"]
		lappend cards $card	
	}
	if {$num_cards > 5} {
		set card [get_property "turn" "card"]
		lappend cards $card	
	}
	if {$num_cards > 6} {
		set card [get_property "river" "card"]
		lappend cards $card	
	}
	return [sort_cards_by_rank $cards]
}

proc is_flush {grouped_by_suit} {
	if {[llength [lindex $grouped_by_suit 0]] == 5} {
		return 1
	}
	return 0
}

proc strait {grouped_by_rank} {
	set result ""
	foreach list $grouped_by_rank {
		lappend result [lindex $list 0]
	}
	if {[llength $result] < 5} {
		return ""
	}
	set cards [sort_cards_by_rank $result]
	
	# First, check for raw strait (no 5 4 3 2 A)
	set value0 [card_rank_value [lindex $cards 0]]
	set value1 [card_rank_value [lindex $cards 1]]
	set value2 [card_rank_value [lindex $cards 2]]
	set value3 [card_rank_value [lindex $cards 3]]
	set value4 [card_rank_value [lindex $cards 4]]
	
	if {($value0 - $value1) == 1 && ($value1 - $value2) == 1 && ($value2 - $value3) == 1 &&
			($value3 - $value4) == 1} {
		set cards [lrange $cards 0 4]
		return $cards
	} elseif {$value0 == 14} {
		set value4 [card_rank_value [lindex $cards [expr [llength $cards] - 1]]]
		set value3 [card_rank_value [lindex $cards [expr [llength $cards] - 2]]]
		set value2 [card_rank_value [lindex $cards [expr [llength $cards] - 3]]]
		set value1 [card_rank_value [lindex $cards [expr [llength $cards] - 4]]]
		
		if {$value4 == 2 && $value3 == 3 && $value2 == 4 && $value1 == 5} {
			set return [list [lindex $cards [expr [llength $cards] - 4]] [lindex $cards [expr [llength $cards] - 3]] [lindex $cards [expr [llength $cards] - 2]] [lindex $cards [expr [llength $cards] - 1]] [lindex $cards 0]]
			return $return
		}
	}
	return 0
}

proc is_strait {grouped_by_rank} {
	set strait [strait $grouped_by_rank]
	return [expr [llength $strait] == 5]
}

proc has_four_of_a_kind {grouped_by_rank} {
	set l [lindex $grouped_by_rank 0]
	set ll [llength $l]
	if {$ll == 4} {
		return 1
	}
	return 0
}

proc is_full_house {grouped_by_rank} {
	set lists [truncate_list_list_to_five_cards $grouped_by_rank]
	set ll1 [llength [lindex $lists 0]]
	set ll2 [llength [lindex $lists 1]]
	if {($ll1 == 3) && ($ll2 == 2)} {
		return 1
	}
	return 0
}

proc has_three_of_a_kind {grouped_by_rank} {
	set list [lindex $grouped_by_rank 0]
	return [expr [llength $list] == 3]
}

proc has_pair {grouped_by_rank} {
	set list [lindex $grouped_by_rank 0]
	return [expr [llength $list] == 2]
}

proc truncate_list_list_to_five_cards {lists} {
	set return {}
	foreach list $lists {
		set room 5
		foreach r $return {
			set lr [llength $r]
			set room [expr $room - $lr]
		}
		if {$room == 0} {
			break
		}
		set l [llength $list]
		if {$l <= $room} {
			lappend return $list
		} else {
			lappend return [lrange $list 0 [expr $room - 1]]
		}
	}
	return $return
}

proc compare_suit_lists {l1 l2} {
	set ll1 [llength $l1]
	set ll2 [llength $l2]
	if {$ll1 < $ll2} {
		return -1
	} elseif {$ll1 > $ll2} {
		return 1
	} else {
		foreach c1 $l1 c2 $l2 {
			set c1_rank [card_rank_value $c1]
			set c2_rank [card_rank_value $c2]
			if {$c1_rank < $c2_rank} {
				return -1
			} elseif {$c1_rank > $c2_rank} {
				return 1
			} else {
			}
		}
		return 0
	}
}

proc group_by_suit {cards} {
	set S {}
	set H {}
	set D {}
	set C {}
	
	foreach card $cards {
		set suit [card_suit $card]
		# Doing this on purpose
		lappend $suit $card
	}
	set lists {}
	foreach s [list $S $H $D $C] {
		if {[llength $s] > 0} {
			lappend lists $s
		}
	}
	set lists [lsort -decreasing -command compare_suit_lists $lists]
	set lists [truncate_list_list_to_five_cards $lists]
	return $lists
}

proc compare_rank_lists {l1 l2} {
	set ll1 [llength $l1]
	set ll2 [llength $l2]
	if {$ll1 < $ll2} {
		return -1
	} elseif {$ll1 > $ll2} {
		return 1
	} else {
		if {$ll1 == 0} {
			return 0
		}
		set rank1 [card_rank_value [lindex $l1 0]]
		set rank2 [card_rank_value [lindex $l2 0]]
		if {$rank1 < $rank2} {
puts "[lindex $l1 0] < [lindex $l2 0]"
error {}
			return -1
		} elseif {$rank1 > $rank2} {
			return 1
		} else {
			error "This should never happen - $l1 vs $l2"
		}
	}
}

proc group_by_rank {cards} {
	set 14 {}
	set 13 {}
	set 12 {}
	set 11 {}
	set 10 {}
	set 9 {}
	set 8 {}
	set 7 {}
	set 6 {}
	set 5 {} 
	set 4 {}
	set 3 {}
	set 2 {}
	
	foreach card $cards {
		set rank [card_rank_value $card]
		# Doing this on purpose
		lappend $rank $card
	}
	set lists {}
	foreach l [list $14 $13 $12 $11 $10 $9 $8 $7 $6 $5 $4 $3 $2] {
		if {[llength $l] > 0} {
			lappend lists $l
		}
	}
	set lists [lsort -decreasing -command compare_rank_lists $lists]
	return $lists
}


set hand_types [list "Royal Flush" "Strait Flush" "Four of a Kind" "Full House" "Flush" "Strait" "Three of a Kind" "Two Pair" "Pair" "High Card"]
set hand_type_values [list 10 9 8 7 6 5 4 3 2 1]
foreach value $hand_type_values string $hand_types {
	set_property $string "tally" 0
	set_property $string "value" $value
	set_property $value "string" $string
}

# returns a triple. 0 element is hand type; 1 is hand power; 2 is a list of secondary values
proc determine_hand_power {player} {
	set cards [get_player_hand $player]
	set grouped_by_suit [group_by_suit $cards]
	set grouped_by_rank [group_by_rank $cards]

	# Royal flush
	if {[is_flush $grouped_by_suit]} {
		set list [lindex $grouped_by_suit 0]
		if {[card_rank_value [lindex $list 0]] == 14} {
			set grouped_flush_by_rank [group_by_rank $list]
			if {[is_strait $grouped_flush_by_rank]} {
				return [list "Royal Flush" {} {}]
			}
		}
	}
	
	# Strait Flush
	if {[is_flush $grouped_by_suit]} {
		set list [lindex $grouped_by_suit 0]
		set grouped_flush_by_rank [group_by_rank $list]
		if {[is_strait $grouped_flush_by_rank]} {
			return [list "Strait Flush" [lindex $grouped_by_suit 0] {}]
		}
	}
	
	# Four of a Kind
	if {[has_four_of_a_kind $grouped_by_rank]} {
		return [list "Four of a Kind" [card_rank_value [lindex $cards 0]] [lrange $cards 1 4]]
	}

	# Full House
	if {[is_full_house $grouped_by_rank]} {
		return [list "Full House" [lindex $grouped_by_rank 0] [lindex $grouped_by_rank 1]]
	}
	
	# Flush
	if {[is_flush $grouped_by_suit]} {
		return [list "Flush" [lindex $grouped_by_suit 0] [lrange $grouped_by_suit 1 4]]
	}
	
	# strait
	if {[is_strait $grouped_by_rank]} {
		set strait [strait $grouped_by_rank]
		return [list "Strait" [lindex $strait 0] {}]
	}
	
	# Three of a Kind
	if {[has_three_of_a_kind $grouped_by_rank]} {
		return [list "Three of a Kind" [lindex $grouped_by_rank 0] [lrange $grouped_by_rank 3 4]]
	}
	
	# Two Pair
	if {[has_pair $grouped_by_rank]} {
		set remainder [lrange $grouped_by_rank 1 end]
		if {[has_pair $remainder]} {
			return [list "Two Pair" [lindex $grouped_by_rank 0] [lindex $remainder 0] [lindex $grouped_by_rank 4]]
		} else {
		}
	}
	
	# Pair
	if {[has_pair $grouped_by_rank]} {
		return [list "Pair" [lindex $grouped_by_rank 0] [lrange $grouped_by_rank 2 4]]
	}
	
	# High Card
	return [list "High Card" [lindex $cards 0] [lrange $cards 1 4]]
}
set winning_players {}
set winning_type {}
set winning_value {}
set winning_seconary {}

proc output_hands {} {
	global num_players
	global winning_players
	global winning_type
	global winning_value
	global winning_secondary
	
	for {set i 0} {$i < $num_players} {incr i} {
		set hand_power [determine_hand_power $i]
puts $hand_power
		set hand_type [lindex $hand_power 0]
puts $hand_type
		set hand_value [lindex $hand_power 1]
puts $hand_value
		set secondary_value [lindex $hand_power 2]
puts $secondary_value
		incr_property $hand_type "tally"
		
		if {[string equal $winning_players {}] || ($hand_type < $winning_type)} {
puts "Better hand type."
puts $winning_players
puts $hand_type
puts $winning_type
			lappend winning_players $i
			set winning_type $hand_type
			set winning_value $hand_value
			set winning_secondary $secondary_value
		} elseif {$hand_type == $winning_type} {
puts "Equal hand type."
puts $winning_players
puts $hand_type
puts $winning_type
puts $hand_value
puts $winning_value
		    set values_equal 1
			foreach value $hand_value winning_value $winning_value {
puts "$value vs $winning_value"
				set rank_value [card_rank_value $value]
				set rank_winning_value [card_rank_value $winning_value]
puts $rank_value
puts $rank_winning_value
exit
				if {$rank_value > $rank_winning_value} {
puts "Better hand value."
					set winning_players $i
					set winning_type $hand_type
					set winning_value $hand_value
					set winning_secondary $secondary_value
					set values_equal 0
puts $winning_players
puts $hand_type
puts $winning_type
puts $hand_value
puts $winning_value
puts "Line 526"
exit
					break
				} elseif {$rank_value < $rank_winning_value} {
puts "Not a better hand."
					set values_equal 0
puts "Line 533"
exit
				}
			}
			if {$values_equal} {
				foreach value $secondary_value winning_value $winning_secondary {
puts "$value vs $winning_value"
					set rank_value [card_rank_value $value]
					set rank_winning_value [card_rank_value $winning_value]
puts $rank_value
puts $rank_winning_value
					if {$rank_value > $rank_winning_value} {
puts "Better secondary value."
						set winning_players $i
						set winning_type $hand_type
						set winning_value $hand_value
						set winning_secondary $secondary_value
						set values_equal 0
puts $winning_players
puts $hand_type
puts $winning_type
puts $hand_value
puts $winning_value
puts $secondary_value
puts $winning_secondary
puts "line 554"
exit
						break
					} elseif {$rank_value < $rank_winning_value} {
puts "Not a better hand."
						set values_equal 0
puts "Line 564"
exit
					}				
				}
			}
			if {$values_equal} {
puts "Same value."
puts $winning_players
puts $hand_type
puts $winning_type
puts $hand_value
puts $winning_value
puts $secondary_value
puts $winning_secondary
puts "line 569"
exit
				lappend winning_players $i
			}
		} else {
puts "Not a better hand."
puts $winning_players
puts $hand_type
puts $winning_type
puts $hand_value
puts $winning_value
puts $secondary_value
puts $winning_secondary
		}
puts ""
	}
puts "Done processing."
puts $winning_players
exit

	set win_value [expr 1 / [llength $winning_players]]
	for {set i 0} {$i < $num_players} {incr i} {
		set wins [get_property "player$i" "wins"]
		if {![string equal $wins ""]} {
		    set wins 0
		}
		incr wins $win_value
		set_property "player$i" "wins" $win_value
	}		
}

proc output_results {} {
	global hand_types
	global num_players
	
	foreach type $hand_types {
		set tally [get_property $type "tally"]
		puts "$type - $tally"
	}
	puts ""
	for {set i 0} {$i < $num_players} {incr i} {
		set wins [get_property "player$i" "wins"]
		puts "Player #$i - $wins"
	}
}

parse_args
for {set iteration 0} {$iteration < $iterations} {incr iteration} {
	set winning_players {}
	set winning_type {}
	set winning_value {}
	set winning_seconary {}
	set new_cards [shuffle_cards $cards]
	process_cards $new_cards
	output_hands
}
output_results
