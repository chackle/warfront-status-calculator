import Foundation

/****************** CHANGE THESE CONSTANTS FOR TESTING *******************/

let dayOfTheYear = 250 // The current day of the year 0 - 365 (366 in a leap year)

let cycleStartDayOfTheYear = 248 // When the cycle started. 248 for EU, 247 US

let serverHourOfTheDay = 15 // The current hour on the realm

let serverMinuteOfTheHour = 30 // The current minutes on the realm

/*************************************************************************/

enum Faction: CustomStringConvertible {
  case alliance
  case horde
  
  static var cycleDuration: Int {
    return WarfrontStatus.duration * 2
  }
  
  static var startingFaction: Faction {
    return .alliance
  }
  
  func warfrontStatus(forFactionCycleDay day: Float) -> WarfrontStatus {
    if day < Float(WarfrontStatus.duration) {
      return self == Faction.startingFaction ? .defending(currentWarfrontCycleDay: day) : .attacking(currentWarfrontCycleDay: day)
    } else {
      return self == Faction.startingFaction ? .attacking(currentWarfrontCycleDay: day - Float(WarfrontStatus.duration)) : .defending(currentWarfrontCycleDay: day - Float(WarfrontStatus.duration))
    }
  }
  
  var description: String {
    switch self {
    case .alliance:
      return "Alliance"
    case .horde:
      return "Horde"
    }
  }
}

enum WarfrontStatus: CustomStringConvertible {
  case defending(currentWarfrontCycleDay: Float)
  case attacking(currentWarfrontCycleDay: Float)
  
  static var duration: Int {
    return Phase.contributing(currentPhaseCycleDay: 0).duration + Phase.scenario(currentPhaseCycleDay: 0).duration
  }
  
  var phase: Phase? {
    switch self {
    case .attacking(let currentWarfrontCycleDay):
      return currentWarfrontCycleDay < Float(Phase.startingPhase.duration) ? .contributing(currentPhaseCycleDay: currentWarfrontCycleDay) : .scenario(currentPhaseCycleDay: currentWarfrontCycleDay)
    case .defending(_):
      return nil
    }
  }
  
  var description: String {
    switch self {
    case .defending(_):
      return "Defending"
    case .attacking(_):
      return "Attacking"
    }
  }
  
  enum Phase: CustomStringConvertible {
    case contributing(currentPhaseCycleDay: Float)
    case scenario(currentPhaseCycleDay: Float)
    
    static var startingPhase: Phase {
      return .contributing(currentPhaseCycleDay: 0)
    }
    
    var duration: Int {
      switch self {
      case .contributing:
        return 5
      case .scenario:
        return 7
      }
    }
    
    var currentProgress: Float? {
      switch self {
      case .contributing(let currentPhaseCycleDay):
        return currentPhaseCycleDay / Float(self.duration)
      case .scenario(_):
        return nil
      }
    }
    
    var description: String {
      switch self {
      case .contributing:
        return "Contributing"
      case .scenario:
        return "Scenario"
      }
    }
  }
}

// Amount of time before the cycle is passed over to the opposite faction
let factionHandOverDuration = WarfrontStatus.duration + WarfrontStatus.duration

let dayOfTheYearDifference = dayOfTheYear - cycleStartDayOfTheYear

let factionCycleDay = Float(dayOfTheYearDifference % Faction.cycleDuration)
let currentDay = (Float(serverHourOfTheDay) + Float(serverMinuteOfTheHour / 60)) / 24

let allianceWarfrontStatus = Faction.alliance.warfrontStatus(forFactionCycleDay: factionCycleDay + currentDay)
let hordeWarfrontStatus = Faction.horde.warfrontStatus(forFactionCycleDay: factionCycleDay + currentDay)

print(Faction.alliance)
print("Warfront Status: \(allianceWarfrontStatus)")
if let phase = allianceWarfrontStatus.phase {
  var phaseString = "Phase: \(phase.description)"
  if let progress = phase.currentProgress {
    phaseString = "\(phaseString) (\(round(progress * 10000) / 100)%)"
  }
  print(phaseString)
} else {
  print("Phase: Access to world boss")
}
print("\n")
print(Faction.horde)
print("Warfront Status: \(hordeWarfrontStatus)")
if let phase = hordeWarfrontStatus.phase {
  var phaseString = "Phase: \(phase.description)"
  if let progress = phase.currentProgress {
    phaseString = "\(phaseString) (\(round(progress * 10000) / 100)%)"
  }
  print(phaseString)
} else {
  print("Phase: Access to world boss")
}

