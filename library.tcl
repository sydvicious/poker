proc remove_card {pos cards} {
  set new_cards [concat [lrange $cards 0 [expr $pos - 1]] [lrange $cards [expr $pos + 1] [llength $cards]]]
  return $new_cards
}

proc get_card_name {card} {
  global ranks
  global suits
  
  set suit_no [expr $card / 100]
  set rank_no [expr $card % 100]
  
  return "[lindex $ranks $rank_no] of [lindex $suits $suit_no]"
}

proc output_card_name {card} {
  puts [get_card_name $card]
}

proc rank_of_card {card} {
  return [expr $card % 100]
}

proc suit_of_card {card} {
  return [expr $card / 100]
}

proc compare_cards {card1 card2} {
  set rank1 [rank_of_card $card1]
  set rank2 [rank_of_card $card2]
  if {$rank1 < $rank2} {
    return -1
  } elseif {$rank1 > $rank2} {
    return 1
  }
  return 0
}

proc output_card_list {cards} {
  set cards [lsort -command compare_cards $cards]
  set output_list {}
  foreach card $cards {
    lappend output_list [get_card_name $card]
  }
  puts $output_list
}

proc is_hand_flush {hand} {
  set suit [suit_of_card [lindex $hand 0]]
  foreach card [lrange $hand 1 end]] {
    if {[suit_of_card $card] != $suit} {
      return 0
    }
  }
  puts "found a flush"
  output_card_list $hand
exit
  return 1
}

proc is_hand_straight {hand} {
puts "is_hand_straight"
output_card_list $hand
exit
}

# Returns -1 if not a n of a kind; otherwise returns position of the n of a kind in the sorted list
proc is_hand_n_of_a_kind {hand n} {
  set hand [lsort -command compare_cards $hand]
  set length [llength $hand]
  if {$length < $n} {
puts "Not enough cards for $n of a kind"
output_card_list $hand
exit
    return -1
  }
  set num_ranges [expr $length - $n + 1]
  for {set i 0} {$i < $num_ranges} {incr i} {
    set card [lindex $hand $i]
    set rank [rank_of_card $card]
    set found 1
    for {set j 1} {$j < $n} {incr j} {
      set card [lindex $hand [expr $i + $j]]
      set new_rank [rank_of_card $card]
      if {$rank != $new_rank} {
	set found 0
	break
      }
    }
    if {$found} {
      return $i
    }
  }
  return -1
}

proc is_hand_full_house {hand} {
  set pos [is_hand_n_of_a_kind $hand 3]
  if {$pos == -1} {
    puts "Not full house - no three of a kind."
    output_card_list $hand
    return 0
  }
  
puts "is_full_house"
output_card_list $hand
exit
}

proc get_hand_kind {hand} {
  set hand [lsort -command compare_cards $hand]
  # Check for royal flush
  if {[is_hand_flush $hand] && [is_hand_straight $hand] && [rank_of_card [$lindex $hand 0] == 0]} {
puts "Found royal flush"
output_card_list $hand
exit
    return 0
  }
  if {[is_hand_n_of_a_kind $hand 4] > -1} {
puts "Found four of a kind"
output_card_list $hand
exit
    return 1
  }
  if {[is_hand_flush $hand] && [is_hand_straight]} {
puts "Found straight flush"
output_card_list $hand
exit
    return 2
  }
  if {[is_hand_full_house $hand]} {
puts "Found full house"
output_card_list $hand
exit
    return 3
}
puts "Unknown hand"
output_card_list $hand
exit
}


