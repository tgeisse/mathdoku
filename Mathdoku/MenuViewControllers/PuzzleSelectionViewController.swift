//
//  PuzzleSelectionViewController.swift
//  Mathdoku
//
//  Created by Taylor Geisse on 4/26/17.
//  Copyright © 2017 Taylor Geisse. All rights reserved.
//

import UIKit
import RealmSwift

class PuzzleSelectionViewController: UIViewController {
    let puzzleLoader = PuzzleLoader()
    lazy var realm: Realm = {try! Realm()}()
    lazy var playerProgress: Results<PlayerProgress> = {
        try! Realm().objects(PlayerProgress.self).sorted(byKeyPath: "puzzleSize", ascending: true)
    }()
    
    var selectedPuzzleSize: Int = -1 {
        didSet{
            puzzleLoader.preloadPuzzle(forSize: selectedPuzzleSize, withPuzzleId: activePuzzleId)
        }
    }
    var selectedButton: UIButton? {
        didSet {
            oldValue?.backgroundColor = UIColor.white
            selectedButton?.backgroundColor = selectColor
            startPuzzle.isEnabled = selectedButton != nil
        }
    }
    var activePuzzleId: Int {
        return playerProgress[selectedPuzzleSize - 3].activePuzzleId
    }
    
    private let selectColor = UIColor(red: 1.0, green: 0.9648, blue: 0.60, alpha: 1.0)
    
    @IBOutlet weak var startPuzzle: UIButton!
    @IBOutlet weak var puzzlesRemainingLabel: UILabel!
    
    private var puzzleAllowanceNotification: NotificationToken?
   
    // MARK: - View Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
        updateStartButtonTitle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up and configure a few aspects of the UI
        DebugUtil.print(Realm.Configuration.defaultConfiguration.fileURL!)
        updateStartButtonTitle()
        updatePuzzlesRemainingLabel()
        addAllowanceNotification()
        puzzleLoader.loadPuzzleSolvedDefaultHistory()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // see if we can get a new refresh allowawnce
        switch PuzzleProducts.puzzleRefreshMode {
        case .error(let error): DebugUtil.print("Error getting the puzzle refresh mode: \(error)")
        case .purchase:
            DebugUtil.print("Entering purchase block -- nothing should be done since purchasers don't get refresh grants")
        case .freeUser:
            DebugUtil.print("Entering refresh grant block for free users")
            let puzzlesGranted = PuzzlePurchase.grantDailyPuzzleAllowance(withRealm: realm)
            
            if puzzlesGranted > 0 {
                // puzzles were granted, notify the user
                let alert = self.alertWithTitle("More Puzzles!", message: "We've added \(puzzlesGranted) puzzle\(puzzlesGranted == 1 ? "" : "s") to your stash.", buttonLabel: "Game on!")
                self.showAlert(alert)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }
    
    // MARK: - UI Updates
    func updatePuzzlesRemainingLabel() {
        puzzlesRemainingLabel.text = "You have \(PuzzleProducts.puzzleAllowance.allowance) puzzles remaining."
        
    }
    
    func updateStartButtonTitle() {
        if (selectedPuzzleSize < 3 || selectedPuzzleSize > 9) == false {
            startPuzzle.setTitle(playerProgress[selectedPuzzleSize - 3].puzzleProgress?.inProgress == true ? "Continue Puzzle" : "Start Puzzle", for: .normal)
        }
    }
    
    func addAllowanceNotification() {
        puzzleAllowanceNotification = PuzzleProducts.puzzleAllowance.observe { [weak self] change in
            switch change {
            case .change(_):
                self?.updatePuzzlesRemainingLabel()
            case .error(let error):
                DebugUtil.print("An error occurred on the puzzle allowance notifications:\n\(error)")
            case .deleted:
                DebugUtil.print("The object was deleted.")
            }
        }
    }
    
    // MARK: - Button Actions
    @IBAction func puzzleSelection(_ sender: UIButton) {
        if let senderString = sender.currentTitle, let numberPressed = Int(senderString) {
            selectedPuzzleSize = numberPressed
            selectedButton = sender
            updateStartButtonTitle()
        }
    }
    
    // MARK: - In-App Purchase methods
    func segueToStore() {
        DebugUtil.print("Seguing to the puzzle store")
        performSegue(withIdentifier: "Store Segue", sender: self)
    }
    
    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "PuzzleSelection" {
            let allowance = PuzzleProducts.puzzleAllowance
            if (playerProgress[selectedPuzzleSize - 3].puzzleProgress?.inProgress ?? false) || allowance.allowance == AllowanceTypes.puzzle.infiniteAllowance() || allowance.allowance > 0 {
                
                // if the player was already playing the puzzle or they have infinite plays
                // or they have puzzles left, then perform the segue
                return true
            } else {
                // else the player does not have puzzle allowance to play. Prompt to buy or wait
                let mentionRefresh: Bool = PuzzleProducts.userIsFree
                
                AnalyticsWrapper.logEvent(.selectContent, contentType: .presented, id: "id-mainMenuOutOfPuzzles")
                
                let alert = self.alertOutOfPuzzlesAndCanPurchase(mentionRefreshPeriod: mentionRefresh, actionOnConfirm: segueToStore)
                self.showAlert(alert)
                
                return false
            }
        } else {
            return true
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "PuzzleSelection" {
            guard let puzzleViewController = segue.destination as? PuzzleViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            puzzleViewController.puzzle = puzzleLoader.fetchPuzzle(forSize: selectedPuzzleSize, withPuzzleId: activePuzzleId)
            puzzleViewController.puzzleLoader = puzzleLoader
        }
    }
    
    deinit {
        puzzleAllowanceNotification?.invalidate()
    }
}

