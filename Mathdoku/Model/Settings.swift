//
//  Settings.swift
//  Mathdoku
//
//  Created by Taylor Geisse on 11/15/17.
//  Copyright © 2017 Taylor Geisse. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

// Defaults extension for settings variables
extension DefaultsKeys {
    static let singleNoteCellSelection = DefaultsKey<Bool>("singleNoteCellSelection")
    static let clearNotesAfterGuessEntry = DefaultsKey<Bool>("clearNotesAfterGuessEntry")
    
    static let rotateAfterCellEntry = DefaultsKey<Bool>("rotateAfterCellEntry")
    
    static let highlightSameGuessEntry = DefaultsKey<Bool>("highlightSameGuessEntry")
    static let highlightConflictingEntries = DefaultsKey<Bool>("highlightConflictingEntries")
    
    static let fillInGiveMes = DefaultsKey<Bool>("fillInGiveMes")

    static let doubleTapToggleNoteMode = DefaultsKey<Bool>("doubleTapToggleNoteMode")
}

struct Settings {
    static func initialize() {
        if !Defaults.hasKey(.singleNoteCellSelection) {
            Defaults[.singleNoteCellSelection] = false
        }
        
        if !Defaults.hasKey(.clearNotesAfterGuessEntry) {
            Defaults[.clearNotesAfterGuessEntry] = true
        }
        
        if !Defaults.hasKey(.rotateAfterCellEntry) {
            Defaults[.rotateAfterCellEntry] = false
        }
        
        if !Defaults.hasKey(.highlightSameGuessEntry) {
            Defaults[.highlightSameGuessEntry] = true
        }
        
        if !Defaults.hasKey(.highlightConflictingEntries) {
            Defaults[.highlightConflictingEntries] = true
        }
        
        if !Defaults.hasKey(.fillInGiveMes) {
            Defaults[.fillInGiveMes] = false
        }
        
        if !Defaults.hasKey(.doubleTapToggleNoteMode) {
            Defaults[.doubleTapToggleNoteMode] = true
        }
    }
}
