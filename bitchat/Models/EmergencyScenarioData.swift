import SwiftUI

struct ScenarioData: Identifiable {
    let id: String
    let title: String
    let category: String
    let categoryColor: Color
    let call999Script: String
    let doNots: [String]
    let steps: [ScenarioStep]
    let equipmentTypes: [String]
    let evidenceNote: String
    let sources: [SourceRef]
    let interactiveType: InteractiveType?
}

struct ScenarioStep: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

struct SourceRef {
    let name: String
    let url: String
    let note: String
}

enum InteractiveType {
    case cprMetronome
    case flushTimer
    case coolingTimer
    case electricalBranch
    case coolingChecklist
    case loneWorkerBranch
    case spinalGate
}

extension ScenarioData {
    static func all(siteAddress: String) -> [ScenarioData] {
        let addr = siteAddress
        return [
            // 1. Cardiac Arrest
            ScenarioData(
                id: "cardiac",
                title: "Cardiac Arrest",
                category: "Medical",
                categoryColor: Color(red: 0.898, green: 0.282, blue: 0.302),
                call999Script: "Tell them: cardiac arrest, construction site. Address: \(addr)",
                doNots: [
                    "Do not delay compressions to search for AED \u{2014} start immediately",
                    "Do not stop compressions for more than 10 seconds",
                    "Do not press on the ribs \u{2014} hands on centre of breastbone only"
                ],
                steps: [
                    ScenarioStep(title: "Call 999", detail: "Tell them: cardiac arrest, construction site. Address: \(addr)"),
                    ScenarioStep(title: "Check for response", detail: "Shake shoulders firmly. Shout: Are you all right?"),
                    ScenarioStep(title: "Open airway", detail: "One hand on forehead, tilt head back. Lift chin with two fingers."),
                    ScenarioStep(title: "Check breathing", detail: "Look, listen, feel for no more than 10 seconds. Not breathing normally \u{2014} start CPR."),
                    ScenarioStep(title: "30 chest compressions", detail: "Heel of hand on centre of breastbone. Arms straight. Press 5\u{2013}6 cm down, release fully. 100\u{2013}120 per minute."),
                    ScenarioStep(title: "2 rescue breaths", detail: "Pinch nose, seal mouth, watch chest rise. Return to compressions immediately."),
                    ScenarioStep(title: "Attach AED on arrival", detail: "Switch on, follow voice prompts. Clear everyone before shock. Restart CPR immediately after shock."),
                    ScenarioStep(title: "Continue until paramedics arrive", detail: "Swap with another responder every 2 minutes if possible.")
                ],
                equipmentTypes: ["AED", "FIRST_AID_KIT"],
                evidenceNote: "Survival from cardiac arrest with CPR and AED within 3\u{2013}5 minutes can exceed 70%. Without intervention: survival falls 10% per minute (Resuscitation Council UK).",
                sources: [
                    SourceRef(name: "HSE INDG347", url: "", note: "First aid at work guidance"),
                    SourceRef(name: "Resuscitation Council UK", url: "", note: "Adult basic life support guidelines"),
                    SourceRef(name: "BHF 2023", url: "", note: "Cardiac arrest survival statistics")
                ],
                interactiveType: .cprMetronome
            ),

            // 2. Fall from Height
            ScenarioData(
                id: "fall",
                title: "Fall from Height",
                category: "Trauma",
                categoryColor: Color(red: 0.898, green: 0.282, blue: 0.302),
                call999Script: "Tell them: fall from height, suspected spinal injury, ambulance only. Address: \(addr)",
                doNots: [
                    "Do not move the casualty unless in immediate danger",
                    "Do not remove the helmet without a specific airway reason",
                    "Do not allow them to stand even if they say they can",
                    "Do not give food, water, or medication"
                ],
                steps: [
                    ScenarioStep(title: "Call 999", detail: "Tell them: fall from height, suspected spinal injury, ambulance only. Address: \(addr)"),
                    ScenarioStep(title: "Do not move the casualty", detail: "Unless in immediate danger. Say: Help is coming, try not to move."),
                    ScenarioStep(title: "Check airway", detail: "Conscious and breathing: leave as found and monitor. Unconscious, not breathing: minimal head tilt, start CPR \u{2014} life takes priority."),
                    ScenarioStep(title: "Retrieve spinal board", detail: "Send another person to the equipment location shown in this alert."),
                    ScenarioStep(title: "Control visible bleeding", detail: "Firm direct pressure without moving the injured area."),
                    ScenarioStep(title: "Keep them warm", detail: "Blanket or clothing over them, not under. Do not move to apply.")
                ],
                equipmentTypes: ["SPINAL_BOARD", "FIRST_AID_KIT"],
                evidenceNote: "Falls from height account for 28% of UK workplace fatalities (HSE 2024/25). Improper movement is a documented cause of secondary spinal cord injury.",
                sources: [
                    SourceRef(name: "HSE INDG347", url: "", note: "First aid at work guidance"),
                    SourceRef(name: "ANZCOR Guideline 9.1.4 (2024)", url: "", note: "Spinal injury management")
                ],
                interactiveType: .spinalGate
            ),

            // 3. Severe Bleeding
            ScenarioData(
                id: "bleeding",
                title: "Severe Bleeding",
                category: "Trauma",
                categoryColor: Color(red: 0.898, green: 0.282, blue: 0.302),
                call999Script: "Tell them: severe bleeding, construction site. Address: \(addr)",
                doNots: [
                    "Do not remove a blood-soaked dressing \u{2014} add more on top",
                    "Do not apply tourniquet over a joint",
                    "Do not remove a tourniquet once applied \u{2014} paramedics only",
                    "Do not give food, water, or medication"
                ],
                steps: [
                    ScenarioStep(title: "Call 999", detail: "Tell them: severe bleeding, construction site. Address: \(addr)"),
                    ScenarioStep(title: "Protect yourself", detail: "Use gloves if available. If not, a plastic bag or clothing as barrier."),
                    ScenarioStep(title: "Apply firm direct pressure", detail: "Press hard with a clean pad. Blood soaks through: add more on top, do not remove."),
                    ScenarioStep(title: "Raise the injured part", detail: "Above heart height while maintaining pressure. Not if fracture suspected."),
                    ScenarioStep(title: "Hold for minimum 10 minutes", detail: "Do not lift the pad to check."),
                    ScenarioStep(title: "Tourniquet \u{2014} limb amputation or arterial bleed", detail: "At least 5 cm above wound on single bone. Tighten until bleeding stops. Note exact time."),
                    ScenarioStep(title: "Torso, neck, or groin wounds", detail: "Tourniquet cannot be used. Apply haemostatic dressing with sustained firm pressure."),
                    ScenarioStep(title: "Treat for shock", detail: "Lay down, raise legs 20 cm unless spinal injury suspected. Keep warm. No fluids.")
                ],
                equipmentTypes: ["FIRST_AID_KIT", "TOURNIQUET"],
                evidenceNote: "HSE recommends tourniquets for construction site first aid kits (HSE eBulletin, June 2016). Record time of application and communicate to paramedics.",
                sources: [
                    SourceRef(name: "HSE INDG347", url: "", note: "First aid at work guidance"),
                    SourceRef(name: "HSE L74 (2024)", url: "", note: "First aid approved code of practice"),
                    SourceRef(name: "UK Resuscitation Council (2022)", url: "", note: "Catastrophic haemorrhage guidance")
                ],
                interactiveType: nil
            ),

            // 4. Chemical Splash
            ScenarioData(
                id: "chemical",
                title: "Chemical Splash",
                category: "Chemical",
                categoryColor: Color(red: 0.910, green: 0.588, blue: 0.047),
                call999Script: "Tell them: chemical eye or skin exposure, construction site. Address: \(addr)",
                doNots: [
                    "Do not rub the eyes or skin \u{2014} spreads the chemical",
                    "Do not apply any cream, butter, or home remedy",
                    "Do not remove clothing stuck to burned skin \u{2014} flush over it",
                    "Do not attempt to neutralise acid or alkali \u{2014} flush with water only"
                ],
                steps: [
                    ScenarioStep(title: "Flush with water immediately", detail: "Start with any clean water source now, while moving to the eyewash station."),
                    ScenarioStep(title: "Get to eyewash station", detail: "Location shown in this alert. Flush continuously for 20 minutes. Use the timer."),
                    ScenarioStep(title: "Hold eyelids open throughout", detail: "Use fingers to hold lids apart. Rotate eyeball to flush all surfaces. Remove contact lenses as soon as possible."),
                    ScenarioStep(title: "Skin exposure", detail: "Remove contaminated clothing not stuck to skin. Flood skin with cool water for 20 minutes."),
                    ScenarioStep(title: "Call 999 or go to A&E", detail: "All chemical eye injuries require A&E. Take the product label or SDS.")
                ],
                equipmentTypes: ["EYEWASH", "FIRST_AID_KIT"],
                evidenceNote: "Every second of delay in chemical eye flushing increases risk of permanent corneal damage. Minimum flush time is 20 minutes (BS EN 15154).",
                sources: [
                    SourceRef(name: "HSE INDG347", url: "", note: "First aid at work guidance"),
                    SourceRef(name: "NHS Burns Treatment", url: "", note: "Chemical burn management"),
                    SourceRef(name: "COSHH Regulations 2002", url: "", note: "Control of substances hazardous to health"),
                    SourceRef(name: "BS EN 15154", url: "", note: "Emergency safety showers and eye wash equipment")
                ],
                interactiveType: .flushTimer
            ),

            // 5. Electrical Contact
            ScenarioData(
                id: "electrical",
                title: "Electrical Contact",
                category: "Electrical",
                categoryColor: Color(red: 0.910, green: 0.588, blue: 0.047),
                call999Script: "Tell them: electrical injury, construction site. Address: \(addr)",
                doNots: [
                    "Do not touch the casualty until power source is confirmed isolated",
                    "Do not approach a high-voltage source under any circumstances",
                    "Do not use anything wet or metal to move a live source",
                    "Do not apply water to electrical burns",
                    "Do not allow casualty to leave without hospital assessment \u{2014} delayed arrhythmia is a known risk"
                ],
                steps: [
                    ScenarioStep(title: "Do not touch the casualty", detail: "Touching before isolation will electrocute you. This is the first rule."),
                    ScenarioStep(title: "Call 999", detail: "Tell them: electrical injury, construction site. Address: \(addr)"),
                    ScenarioStep(title: "Select voltage type", detail: "Low voltage and high voltage require completely different responses. Use the selector below."),
                    ScenarioStep(title: "Once isolated \u{2014} assess", detail: "Check airway and breathing. Not breathing: start CPR and attach AED immediately.")
                ],
                equipmentTypes: ["AED", "FIRST_AID_KIT"],
                evidenceNote: "All electrical injuries require hospital assessment regardless of apparent severity. Internal burns from electrical current often require major surgery.",
                sources: [
                    SourceRef(name: "HSE Electrical Injuries", url: "", note: "Electrical safety guidance"),
                    SourceRef(name: "HSE INDG347", url: "", note: "First aid at work guidance"),
                    SourceRef(name: "IEC 60479", url: "", note: "Effects of current on human beings")
                ],
                interactiveType: .electricalBranch
            ),

            // 6. Crush Injury
            ScenarioData(
                id: "crush",
                title: "Crush Injury",
                category: "Trauma",
                categoryColor: Color(red: 0.898, green: 0.282, blue: 0.302),
                call999Script: "Tell them: crush injury, person trapped, construction site. Address: \(addr). State how long trapped.",
                doNots: [
                    "Do not allow casualty to stand or walk after release",
                    "Do not assume they are fine because conscious \u{2014} crush syndrome can develop after apparent recovery",
                    "Do not give food or water",
                    "Do not apply tourniquet over the crushed area \u{2014} apply above it"
                ],
                steps: [
                    ScenarioStep(title: "Call 999 before releasing", detail: "Tell them: crush injury, person trapped. Address: \(addr). State how long trapped."),
                    ScenarioStep(title: "Assess scene safety", detail: "Structure and plant must be stable before approaching."),
                    ScenarioStep(title: "Keep them talking", detail: "No food or water. Communicate throughout."),
                    ScenarioStep(title: "Control visible bleeding while trapped", detail: "Direct pressure only. No tourniquet while limb still trapped."),
                    ScenarioStep(title: "Release as quickly as safely possible", detail: "Longer crush time means greater crush syndrome risk."),
                    ScenarioStep(title: "Tourniquet immediately on release \u{2014} limb crush over 15 minutes", detail: "Apply above the crush site at the moment of release."),
                    ScenarioStep(title: "Lay flat, treat for shock", detail: "Do not allow to stand. Blankets over body. No food or fluids."),
                    ScenarioStep(title: "Monitor closely", detail: "Deterioration can be rapid even if casualty appears to recover. Be ready to start CPR.")
                ],
                equipmentTypes: ["FIRST_AID_KIT", "TOURNIQUET"],
                evidenceNote: "Crush syndrome risk rises significantly after 15 minutes of compression (ANZCOR 2026). Paramedics need to be on site at moment of release.",
                sources: [
                    SourceRef(name: "ANZCOR Guideline 9.1.7 (2026)", url: "", note: "Crush injury management"),
                    SourceRef(name: "HSE INDG347", url: "", note: "First aid at work guidance")
                ],
                interactiveType: nil
            ),

            // 7. Burns
            ScenarioData(
                id: "burns",
                title: "Burns",
                category: "Thermal",
                categoryColor: Color(red: 0.910, green: 0.588, blue: 0.047),
                call999Script: "Tell them: burns injury, construction site. Address: \(addr)",
                doNots: [
                    "Do not apply ice, iced water, or cold packs",
                    "Do not apply butter, toothpaste, cream, or any home remedy",
                    "Do not wrap cling film around a limb \u{2014} lay it lengthways",
                    "Do not burst blisters",
                    "Do not remove clothing stuck to burned skin",
                    "Do not apply water to electrical burns \u{2014} dry dressings only"
                ],
                steps: [
                    ScenarioStep(title: "Stop the burning process", detail: "Remove from source. Clothing on fire: stop, drop, roll. Smother with blanket."),
                    ScenarioStep(title: "Call 999 for serious burns", detail: "Burns larger than casualty\u{2019}s hand, face/neck/hands/joints, white or charred skin, any inhalation. Address: \(addr)"),
                    ScenarioStep(title: "Cool with running water for 20 minutes", detail: "Start immediately \u{2014} use the timer. Even hours after injury, cooling reduces depth."),
                    ScenarioStep(title: "Keep person warm while cooling burn", detail: "Blanket over rest of body. Cooling the burn and warming the person are both required."),
                    ScenarioStep(title: "Remove clothing and jewellery", detail: "Carefully remove unless stuck to skin. Never pull off stuck items."),
                    ScenarioStep(title: "Cover loosely", detail: "Cling film laid lengthways, clean plastic bag for hands, or sterile non-fluffy dressing.")
                ],
                equipmentTypes: ["BURNS_KIT", "FIRST_AID_KIT"],
                evidenceNote: "Electrical burns: A&E regardless of size. Inhalation burns are life-threatening \u{2014} call 999 immediately and monitor airway.",
                sources: [
                    SourceRef(name: "HSE INDG347", url: "", note: "First aid at work guidance"),
                    SourceRef(name: "NHS Burns Treatment", url: "", note: "Burns and scalds management")
                ],
                interactiveType: .coolingTimer
            ),

            // 8. Confined Space Rescue
            ScenarioData(
                id: "confined",
                title: "Confined Space Rescue",
                category: "Confined Space",
                categoryColor: Color(red: 0.898, green: 0.282, blue: 0.302),
                call999Script: "Tell them: confined space rescue, person collapsed inside, construction site. Address: \(addr). Fire and Rescue required.",
                doNots: [
                    "Do not enter the space without breathing apparatus \u{2014} you will become a second casualty",
                    "Do not lean into the space to reach the casualty",
                    "Do not turn off ventilation equipment already running",
                    "Do not attempt rescue without the site pre-planned confined space procedure"
                ],
                steps: [
                    ScenarioStep(title: "Call 999", detail: "Fire and Rescue attend with breathing apparatus. Address: \(addr)"),
                    ScenarioStep(title: "Do not enter the space", detail: "The same atmosphere that collapsed the worker will incapacitate you within seconds."),
                    ScenarioStep(title: "Alert permit holder and supervisor", detail: "Activate the site pre-planned confined space rescue procedure."),
                    ScenarioStep(title: "Attempt non-entry rescue first", detail: "If a lifeline is attached, use the retrieval system from outside."),
                    ScenarioStep(title: "Increase ventilation if safe", detail: "Force fresh air into the space without entering."),
                    ScenarioStep(title: "Entry only by trained BA wearers", detail: "Wait for Fire and Rescue if not available on site."),
                    ScenarioStep(title: "On extraction", detail: "Check airway, breathing, circulation. Start CPR if required.")
                ],
                equipmentTypes: ["FIRST_AID_KIT"],
                evidenceNote: "60% of confined space fatalities are would-be rescuers who entered without protection (CCOHS). Confined Spaces Regulations 1997 require pre-planned rescue arrangements.",
                sources: [
                    SourceRef(name: "Confined Spaces Regulations 1997", url: "", note: "Legal requirements for confined space work"),
                    SourceRef(name: "HSE", url: "", note: "Confined space safety guidance"),
                    SourceRef(name: "CDM 2015", url: "", note: "Construction design and management regulations")
                ],
                interactiveType: nil
            ),

            // 9. Breathing Difficulty
            ScenarioData(
                id: "breathing",
                title: "Breathing Difficulty",
                category: "Respiratory",
                categoryColor: Color(red: 0.910, green: 0.588, blue: 0.047),
                call999Script: "Tell them: breathing difficulty, construction site. Address: \(addr)",
                doNots: [
                    "Do not lay a conscious breathing casualty flat",
                    "Do not leave them alone at any point",
                    "Do not re-enter an atmosphere that caused fume inhalation"
                ],
                steps: [
                    ScenarioStep(title: "Call 999", detail: "Tell them: breathing difficulty, construction site. Address: \(addr)"),
                    ScenarioStep(title: "Sit upright, lean slightly forward", detail: "Easiest breathing position. Do not lay flat."),
                    ScenarioStep(title: "Asthma", detail: "Help use their own blue reliever inhaler. One puff every 30\u{2013}60 seconds, up to 10 puffs."),
                    ScenarioStep(title: "Choking \u{2014} conscious", detail: "Can they cough? Encourage coughing. Cannot cough or speak: 5 back blows between shoulder blades, then 5 abdominal thrusts. Repeat."),
                    ScenarioStep(title: "Choking \u{2014} becomes unconscious", detail: "Lower to ground. Call 999. Start CPR \u{2014} compressions may dislodge the object."),
                    ScenarioStep(title: "Carbon monoxide or fume inhalation", detail: "Remove to fresh air immediately. Do not re-enter. Inform 999 of the atmospheric hazard."),
                    ScenarioStep(title: "Anaphylaxis", detail: "Swelling of throat or tongue, rash, rapid deterioration: administer EpiPen to outer thigh if available. Call 999."),
                    ScenarioStep(title: "Casualty stops breathing", detail: "Start CPR immediately \u{2014} Cardiac Arrest protocol.")
                ],
                equipmentTypes: ["FIRST_AID_KIT", "AED", "OXYGEN"],
                evidenceNote: "Multiple workers becoming unwell simultaneously in an enclosed area indicates carbon monoxide. Evacuate everyone and call 999.",
                sources: [
                    SourceRef(name: "HSE INDG347", url: "", note: "First aid at work guidance"),
                    SourceRef(name: "NHS", url: "", note: "Breathing emergencies guidance")
                ],
                interactiveType: nil
            ),

            // 10. Heat Stroke
            ScenarioData(
                id: "heat",
                title: "Heat Stroke",
                category: "Medical",
                categoryColor: Color(red: 0.898, green: 0.282, blue: 0.302),
                call999Script: "Tell them: heat stroke, construction site. Address: \(addr)",
                doNots: [
                    "Do not give fluids to a confused or unconscious casualty \u{2014} aspiration risk",
                    "Do not use ice-cold water immersion \u{2014} cool water only",
                    "Do not allow them to walk it off \u{2014} hospital assessment required",
                    "Do not leave them unattended"
                ],
                steps: [
                    ScenarioStep(title: "Call 999", detail: "Tell them: heat stroke, construction site. Address: \(addr)"),
                    ScenarioStep(title: "Move to shade or cool area", detail: "Out of direct sun and away from hot machinery."),
                    ScenarioStep(title: "Cool by all available means", detail: "Use the checklist. Cool water, fanning, ice packs to neck, armpits, and groin."),
                    ScenarioStep(title: "Position correctly", detail: "Conscious: sit or lie. Confused: lay on side. Unconscious and breathing: recovery position."),
                    ScenarioStep(title: "Monitor closely", detail: "Deterioration can be rapid. Do not leave alone. Be ready to start CPR.")
                ],
                equipmentTypes: ["FIRST_AID_KIT"],
                evidenceNote: "Heat stroke vs exhaustion \u{2014} Exhaustion: heavy sweating, pale, lucid. Stroke: confused, slurred speech, seizure, or loss of consciousness. If in any doubt, treat as heat stroke.",
                sources: [
                    SourceRef(name: "OSHA Heat Illness", url: "", note: "Occupational heat illness prevention"),
                    SourceRef(name: "NHS / Mayo Clinic", url: "", note: "Heat stroke recognition and treatment"),
                    SourceRef(name: "CCOHS", url: "", note: "Heat stress guidelines")
                ],
                interactiveType: .coolingChecklist
            ),

            // 11. Lone Worker Emergency
            ScenarioData(
                id: "lone",
                title: "Lone Worker Emergency",
                category: "Unknown",
                categoryColor: Color(red: 0.541, green: 0.557, blue: 0.588),
                call999Script: "Tell them: lone worker unresponsive, unknown condition, construction site. Address: \(addr)",
                doNots: [
                    "Do not assume the situation is non-serious because the worker is not calling out",
                    "Do not search confined or hazardous areas alone"
                ],
                steps: [
                    ScenarioStep(title: "Respond immediately", detail: "Treat as potentially life-threatening."),
                    ScenarioStep(title: "Call 999 while travelling", detail: "Tell them: lone worker unresponsive, unknown condition. Address: \(addr)"),
                    ScenarioStep(title: "Call out as you approach", detail: "Their response guides your immediate action. Use the condition selector below."),
                    ScenarioStep(title: "Stay with them", detail: "Send a second person to meet emergency services at the site entrance and guide them in.")
                ],
                equipmentTypes: ["FIRST_AID_KIT", "AED"],
                evidenceNote: "SiteNodes flag when a device has not been detected for an unusual period, enabling a lone worker alert before an SOS is manually sent.",
                sources: [
                    SourceRef(name: "HSE INDG73", url: "", note: "Working alone guidance"),
                    SourceRef(name: "CDM 2015", url: "", note: "Construction design and management regulations")
                ],
                interactiveType: .loneWorkerBranch
            )
        ]
    }
}
