import Foundation

/// The fictional person the demo app starts with (no "getting to know you" call).
/// Margaret Weber, 78, lives alone; her daughter Anna helps her. Her medicines match
/// the sample plan image (public/samples/medication-plan.png).
enum DemoPerson {
    static let profile: Profile = {
        var p = Profile()
        p.name = "Margaret Weber"
        p.address_as = "Margaret"
        p.wake_time = "7:00"
        p.breakfast_time = "8:00"
        p.lunch_time = "12:30"
        p.dinner_time = "18:00"
        p.bed_time = "22:00"
        p.hearing = "a little hard of hearing"
        p.eyesight = "reads with glasses"
        p.tech_comfort = "new to smartphones, a bit nervous"
        p.helper_name = "Anna"
        p.helper_relation = "daughter"
        p.doctor_name = "Dr Hoffmann"
        return p
    }()

    /// Starts empty: the demo shows scanning her medication plan.
    /// What Margaret starts with: her five medicines and two upcoming appointments (demo data).
    static var plan: Plan {
        var p = samplePlan
        p.appointments = [
            Appointment(title: "Heart ultrasound (echocardiogram)", date: "Thursday, 29 October 2026", time: "09:30",
                        place: "Example Heart Clinic, Building B, Room 214",
                        bring: "insurance card, medication plan, referral from Dr Hoffmann",
                        preparation: "Eat and drink as normal; take your usual morning medicines."),
            Appointment(title: "Eye check-up", date: "Tuesday, 3 November 2026", time: "10:15",
                        place: "Example Eye Clinic, 2nd floor",
                        bring: "glasses and insurance card",
                        preparation: "Eye drops are used: do not drive afterwards."),
        ]
        return p
    }

    /// The five medicines on the sample plan image (Settings: load it if scanning fails).
    static let samplePlan = Plan(medications: [
        med("Ramipril", "5 mg", "for high blood pressure", morning: "1"),
        med("Metformin", "500 mg", "for diabetes", morning: "1", evening: "1", "with meals"),
        med("Simvastatin", "20 mg", "for cholesterol", evening: "1"),
        med("Acetylsalicylic acid (ASS 100)", "100 mg", "to protect the heart", morning: "1", "after breakfast"),
        med("Pantoprazole", "20 mg", "to protect the stomach", morning: "1", "30 min before breakfast"),
    ])

    private static func med(_ name: String, _ strength: String, _ purpose: String,
                            morning: String = "", midday: String = "", evening: String = "", night: String = "",
                            _ instructions: String = "") -> Medication {
        Medication(name: name, strength: strength, purpose: purpose,
                   times: Times(morning: morning, midday: midday, evening: evening, night: night),
                   instructions: instructions)
    }
}
