import Foundation

enum Region {
  case eu
  case us
}

/****************** CHANGE THESE VARIABLES FOR TESTING *******************/

let region = Region.eu
let calendar = Calendar.current
let date = Date()

let cycleStartDayOfTheYear = region == .eu ? 248 : 247 // When the cycle started. 248 for EU, 247 US

let dayOfTheYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 0 // The current day of the year 0 - 365 (366 in a leap year)

let serverHourOfTheDay = calendar.ordinality(of: .hour, in: .day, for: date) ?? 0 // The current hour on the realm

let serverMinuteOfTheHour = calendar.ordinality(of: .minute, in: .hour, for: date) ?? 0 // The current minutes on the realm

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

func jsonObject(forFaction faction: Faction, andFactionCycleDay factionCycleDay: Float) -> [String:Any?] {
  let warfrontStatus = faction.warfrontStatus(forFactionCycleDay: factionCycleDay)
  var warfrontStatusData = [
    "type": warfrontStatus.description.lowercased(),
    "phase": nil
  ] as [String:Any?]
  if let phase = warfrontStatus.phase {
    warfrontStatusData["phase"] = [
      "type": phase.description.lowercased(),
      "progress": phase.currentProgress
    ]
  }
  return warfrontStatusData
}

// Amount of time before the cycle is passed over to the opposite faction
let factionHandOverDuration = WarfrontStatus.duration + WarfrontStatus.duration

let dayOfTheYearDifference = dayOfTheYear - cycleStartDayOfTheYear

let factionCycleDay = Float(dayOfTheYearDifference % Faction.cycleDuration) + (Float(serverHourOfTheDay) + Float(serverMinuteOfTheHour / 60)) / 24
let factionWarfrontStatus = [
  "\(Faction.alliance.description.lowercased())_status": jsonObject(forFaction: Faction.alliance, andFactionCycleDay: factionCycleDay),
  "\(Faction.horde.description.lowercased())_status": jsonObject(forFaction: Faction.horde, andFactionCycleDay: factionCycleDay)
]
do {
  let jsonData = try JSONSerialization.data(withJSONObject: factionWarfrontStatus, options: .prettyPrinted)
  if let jsonResponse = String(data: jsonData, encoding: .utf8) {
    print(jsonResponse)
  }
} catch {
  print("Error: \(error.localizedDescription)")
}

