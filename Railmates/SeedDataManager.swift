import Foundation
import FirebaseFirestore

@MainActor
class SeedDataManager {
    static let shared = SeedDataManager()
    private let db = Firestore.firestore()

    // Fake author IDs and names for seeded content
    private let authors: [(id: String, name: String)] = [
        ("seed_user_sofia",   "Sofia K."),
        ("seed_user_marcus",  "Marcus B."),
        ("seed_user_lena",    "Lena H."),
        ("seed_user_thomas",  "Thomas W."),
        ("seed_user_anna",    "Anna P."),
        ("seed_user_jakob",   "Jakob R."),
        ("seed_user_mia",     "Mia L.")
    ]

    func seedAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.seedTips() }
            group.addTask { await self.seedGuides() }
            group.addTask { await self.seedStories() }
            group.addTask { await self.seedJournals() }
            group.addTask { await self.seedTrips() }
        }
    }

    // MARK: - Tips

    private func seedTips() async {
        let tips: [[String: Any]] = [
            tip("Free luggage lockers at Amsterdam Centraal", category: "Station Tip",
                location: "Amsterdam Centraal", lat: 52.3791, lon: 4.9003,
                desc: "Level -1 has free coin-return lockers if you arrive before noon. Bring a €2 coin as deposit — you get it back. Beats the paid ones by the exit.",
                author: authors[0], likes: ["seed_user_marcus", "seed_user_lena"]),

            tip("Secret viewpoint above Prague", category: "Hidden Gem",
                location: "Vítkov Hill, Prague", lat: 50.0893, lon: 14.4598,
                desc: "Climb the Vítkov monument hill just east of the centre. Zero tourists, panoramic view of the whole city. Free, open all day. 15 min walk from Žižkov tram stop.",
                author: authors[1], likes: ["seed_user_sofia", "seed_user_anna", "seed_user_jakob"]),

            tip("Ruin bars are cheapest on weeknights", category: "Hidden Gem",
                location: "Szimpla Kert, Budapest", lat: 47.4994, lon: 19.0636,
                desc: "Budapest's famous ruin bars charge no entry Mon–Thu. Beer is under €2. Weekends have cover charges and queues. Sunday farmer's market at Szimpla is free and great.",
                author: authors[2], likes: ["seed_user_sofia", "seed_user_marcus"]),

            tip("Night train hack: book the couchette, not the seat", category: "Station Tip",
                location: "Wien Hauptbahnhof", lat: 48.1841, lon: 16.3792,
                desc: "On the Vienna–Venice Nightjet, upgrading from seat to 6-berth couchette costs about €15 extra but means actual sleep. Book at least 3 weeks ahead for availability.",
                author: authors[3], likes: ["seed_user_lena", "seed_user_mia", "seed_user_sofia"]),

            tip("Best cheap eat near the Sagrada Família", category: "Food",
                location: "Carrer de Provença, Barcelona", lat: 41.4036, lon: 2.1744,
                desc: "Walk two blocks west to Carrer de Provença — menú del día (3-course lunch with wine) for €10. The tourist restaurants right at the entrance charge double for half the quality.",
                author: authors[4], likes: ["seed_user_jakob"]),

            tip("Free water refill fountains in Rome", category: "Hidden Gem",
                location: "Nasoni, Rome", lat: 41.8986, lon: 12.4769,
                desc: "Rome has over 2,500 'nasoni' — small green drinking fountains — throughout the city. The water is clean, cold, and delicious. Never buy a bottle again. Just search 'nasoni' on Maps.",
                author: authors[5], likes: ["seed_user_sofia", "seed_user_thomas", "seed_user_anna", "seed_user_lena"]),

            tip("Left luggage cheaper than station at Berlin Hbf", category: "Station Tip",
                location: "Berlin Hauptbahnhof", lat: 52.5251, lon: 13.3694,
                desc: "The DB Gepäck lockers cost €5–7/day. Instead, walk 400m to the Ibis hotel reception — they store bags for €3 per bag per day, no booking needed. Locals-only trick.",
                author: authors[6], likes: ["seed_user_marcus", "seed_user_jakob"]),

            tip("Tram 28 in Lisbon: take it at 9am, not noon", category: "Hidden Gem",
                location: "Alfama, Lisbon", lat: 38.7133, lon: -9.1291,
                desc: "The famous Tram 28 is a tourist trap by midday — packed, pickpockets active. At 9am it's mostly locals and you get a seat. Alfama views are better in morning light anyway.",
                author: authors[0], likes: ["seed_user_lena", "seed_user_thomas"]),

            tip("Free city bike rental in Copenhagen", category: "Hidden Gem",
                location: "Donkey Republic, Copenhagen", lat: 55.6861, lon: 12.5700,
                desc: "Copenhagen City Bikes are free for the first hour — enough to cycle the whole harbour front from Nyhavn to the Little Mermaid and back. Dock them at any station.",
                author: authors[1], likes: ["seed_user_sofia", "seed_user_mia", "seed_user_anna"]),

            tip("Avoid Schiphol rail vending machines", category: "Station Tip",
                location: "Amsterdam Schiphol Airport", lat: 52.3105, lon: 4.7683,
                desc: "The yellow NS vending machines at Schiphol charge a €1 surcharge per ticket for international credit cards. Use the NS app or the blue ticket windows — no surcharge.",
                author: authors[2], likes: ["seed_user_jakob", "seed_user_thomas"]),

            tip("Best döner in Vienna for €4", category: "Food",
                location: "Naschmarkt, Vienna", lat: 48.1990, lon: 16.3640,
                desc: "Yasin Doner on Linke Wienzeile, just off the Naschmarkt. Huge portions, fresh bread, €3.80. Been there since 1998. Open until 2am — perfect after a late train arrival.",
                author: authors[3], likes: ["seed_user_sofia", "seed_user_lena", "seed_user_mia"]),

            tip("Hostel with free sauna in Stockholm", category: "Hostel",
                location: "Generator Stockholm", lat: 59.3346, lon: 18.0584,
                desc: "Generator Stockholm has a free sauna for guests every evening 6–9pm. Rooftop bar with views. Dorms from €25. Book the corner bunk on floor 4 — it has a private curtain.",
                author: authors[4], likes: ["seed_user_jakob", "seed_user_marcus"]),

            tip("Spritz in Venice costs €1.50 at the right bar", category: "Food",
                location: "Campo Santa Margherita, Venice", lat: 45.4350, lon: 12.3266,
                desc: "Stand at the bar (not sit at a table) at any bacaro around Campo Santa Margherita. A Spritz Aperol or Campari with a cicchetto snack is €1.50–2. Sitting triples the price.",
                author: authors[5], likes: ["seed_user_anna", "seed_user_thomas", "seed_user_sofia"]),

            tip("Munich Hauptbahnhof has showers", category: "Station Tip",
                location: "München Hauptbahnhof", lat: 48.1402, lon: 11.5582,
                desc: "After overnight trains, the DB Reisezentrum on level B2 has showers for €7 including towel. Open 6am–10pm. Cheaper than a hotel, perfect for turning around before exploring.",
                author: authors[6], likes: ["seed_user_lena", "seed_user_marcus"]),

            tip("Edinburgh's free Royal Mile walking route", category: "Hidden Gem",
                location: "Royal Mile, Edinburgh", lat: 55.9486, lon: -3.1892,
                desc: "Walk the Royal Mile top-to-bottom (Castle to Holyrood) then detour up Arthur's Seat for 360° views. All free. Takes about 4 hours. Avoid the souvenir shops in the middle — 3x markup.",
                author: authors[0], likes: ["seed_user_mia", "seed_user_sofia"]),

            tip("Best free beach near Dubrovnik", category: "Hidden Gem",
                location: "Šulić Beach, Dubrovnik", lat: 42.6518, lon: 18.0823,
                desc: "Banje Beach in Dubrovnik is crowded and charges €30/day for sunbeds. Walk 20 min south to Šulić beach — rocks but crystal water, no charge, half the tourists. Bring water shoes.",
                author: authors[1], likes: ["seed_user_thomas", "seed_user_anna", "seed_user_jakob"]),

            tip("Zurich's free city swim — the Limmat", category: "Hidden Gem",
                location: "Oberer Letten, Zurich", lat: 47.3879, lon: 8.5327,
                desc: "In summer, locals swim the River Limmat for free at Oberer Letten. Lockers, grass, river current does the work — jump in upstream and float down. Bring a waterproof bag.",
                author: authors[2], likes: ["seed_user_sofia", "seed_user_lena"]),

            tip("Polish border crossing: always have cash", category: "Station Tip",
                location: "Terespol Border, Poland", lat: 52.0773, lon: 23.6157,
                desc: "The Warsaw–Kiev and Warsaw–Vilnius overnight trains cross borders where card machines often fail. Keep €20 in local cash for border fees, food, and emergency taxis.",
                author: authors[3], likes: ["seed_user_marcus"]),

            tip("Cheap pasta spot steps from Roma Termini", category: "Food",
                location: "Roma Termini", lat: 41.9009, lon: 12.5016,
                desc: "Mercato Centrale inside Roma Termini has a pasta stall on the ground floor. Fresh cacio e pepe for €5. Ignore the overpriced bars at the platforms — walk through the main hall.",
                author: authors[4], likes: ["seed_user_sofia", "seed_user_lena", "seed_user_mia"]),

            tip("Free walking tour: every major city has one", category: "Hidden Gem",
                location: "Various European Cities", lat: 50.0755, lon: 14.4378,
                desc: "SANDEMANs runs free (tip-based) walking tours in 30+ European cities. Check the website for meeting points. 2–3 hours, knowledgeable local guides, great way to orient on day 1.",
                author: authors[5], likes: ["seed_user_jakob", "seed_user_anna", "seed_user_thomas"])
        ]

        for t in tips {
            try? await db.collection("locationTips").addDocument(data: t)
        }
    }

    private func tip(_ title: String, category: String, location: String,
                     lat: Double, lon: Double, desc: String,
                     author: (id: String, name: String), likes: [String]) -> [String: Any] {
        [
            "title": title,
            "category": category,
            "locationName": location,
            "latitude": lat,
            "longitude": lon,
            "description": desc,
            "createdBy": author.id,
            "createdAt": Timestamp(date: randomPastDate(within: 90)),
            "likedBy": likes,
            "ratingSum": Int.random(in: 3...25),
            "ratingCount": Int.random(in: 1...8)
        ]
    }

    // MARK: - Guides

    private func seedGuides() async {
        let guides: [[String: Any]] = [
            guide(title: "How to book Eurail without getting ripped off",
                  category: "Booking", country: "Europe",
                  lat: 52.3676, lon: 4.9041,
                  author: authors[0],
                  likes: ["seed_user_marcus", "seed_user_lena", "seed_user_thomas"],
                  content: """
Eurail passes look expensive up front, but they save serious money if you're doing more than 4 countries. Here's what the booking sites don't tell you:

**Reservation fees are extra.** A Eurail pass gives you the right to board — but most high-speed and night trains require a separate seat reservation (€5–35). Budget for this. France and Italy are the worst offenders.

**Buy before you arrive.** Passes are cheaper on the Eurail website than at any station. If you're a student under 27, always select the Youth fare — 35% discount.

**The 'flexi' pass is usually better.** Unless you're on a brutal daily schedule, a 15-day or 1-month flexi pass (travel any X days within a period) beats a continuous pass. Most people take days off.

**Validate before you board.** You must activate your pass online before your first travel day. Forget this and inspectors will treat it as invalid.

**Book night train couchettes early.** The reservation for night trains books out weeks ahead. Set a reminder for exactly 90 days before your target date — that's when DB, ÖBB, and SNCF release inventory.
"""),

            guide(title: "The best 3-week InterRail route for first-timers",
                  category: "Routes", country: "Europe",
                  lat: 48.8566, lon: 2.3522,
                  author: authors[1],
                  likes: ["seed_user_sofia", "seed_user_anna", "seed_user_jakob", "seed_user_mia"],
                  content: """
Three weeks is the sweet spot. Long enough to feel Europe, short enough not to burn out. Here's the route I recommend:

**Week 1: Western Arc**
Paris (2 nights) → Amsterdam (2 nights) → Brussels (1 night) → Paris

**Week 2: Central Europe**
Paris → Munich (overnight train) → Vienna (2 nights) → Prague (2 nights) → Krakow (1 night)

**Week 3: South**
Krakow → Budapest (2 nights) → Ljubljana (1 night) → Venice (2 nights) → home

**Why this works:**
- Each leg is 3–8 hours, no brutal day trips
- Night train Munich→Vienna saves a hotel night
- Prague and Budapest are the cheapest for food and accommodation
- Ljubljana is underrated and beautiful
- Venice for the finale feels rewarding

**What to skip on your first trip:** Spain (too far for 3 weeks unless you fly one way), Scandinavia (expensive), Greece (long train journey from central Europe).
"""),

            guide(title: "Eurail vs. point-to-point tickets: which is cheaper?",
                  category: "Passes", country: "Europe",
                  lat: 47.3769, lon: 8.5417,
                  author: authors[2],
                  likes: ["seed_user_sofia", "seed_user_marcus"],
                  content: """
The honest answer: it depends on how you travel. Here's the breakdown.

**Passes win if:**
- You're crossing 5+ countries
- You're traveling spontaneously without fixed dates
- You're making multiple shorter hops (passes have no per-km cost once purchased)
- You want the flexibility to hop on regional trains without booking

**Point-to-point wins if:**
- You have fixed travel dates and book 3+ months ahead (advance fares can be 60% cheaper)
- You're doing 2–3 countries with direct trains (e.g., Amsterdam–Paris–Brussels)
- You're using budget airlines for one leg (a €30 Ryanair flight often beats a pass day)

**The reservation trap:** Even with a pass, Paris–Lyon TGV, Rome–Naples Frecciarossa, and all Eurostar/Thalys trains charge mandatory reservations. If you're doing a lot of these, your "free" pass is costing €25/segment extra.

**My rule:** Price out your exact route on Rail Europe's point-to-point calculator. If the pass saves >€80 on paper, get it — the flexibility premium is worth the gap.
"""),

            guide(title: "How I traveled 3 weeks in Europe for under €800",
                  category: "Budget", country: "Europe",
                  lat: 47.4979, lon: 19.0402,
                  author: authors[3],
                  likes: ["seed_user_lena", "seed_user_anna", "seed_user_jakob", "seed_user_sofia", "seed_user_mia"],
                  content: """
€800 for 21 days. Here's every line item.

**Transport: €220**
- Eurail Global 7-day flexi pass (Youth): €180
- Train reservations (night trains + TGV): €40

**Accommodation: €315**
- 18 nights in hostels, avg €17.50/night
- 3 nights on night trains (saved 3 hotel nights)

**Food: €180**
- Breakfast: free at hostels or €2 bakeries
- Lunch: supermarket — €3–4/day
- Dinner: budget restaurant every other day, otherwise supermarket
- Never paid more than €12 for a dinner

**Extras: €85**
- 2 museum entries (Prague castle, Vienna Belvedere)
- City transport passes where needed
- One splurge dinner in Vienna (€25)
- Miscellaneous snacks, coffees

**Top money savers:**
1. Night trains eliminate hotel nights
2. Supermarket lunch every day saves €8–12 vs. cafés
3. Free walking tours instead of €20 paid tours
4. Hostels with free breakfast only
5. City museums are often free on first Sunday of the month
"""),

            guide(title: "The only packing list you need for train travel",
                  category: "Packing", country: "Europe",
                  lat: 52.5200, lon: 13.4050,
                  author: authors[4],
                  likes: ["seed_user_thomas", "seed_user_marcus", "seed_user_lena"],
                  content: """
After 15 InterRail trips, this list has never let me down. The rule: carry-on only. You'll thank yourself at every train change.

**The bag:** 40L backpack max. I use a Osprey Farpoint 40. Fits in overhead racks, no check-in, no waiting.

**Clothes (1 week, fast-dry everything):**
- 3× t-shirts (merino or synthetic)
- 2× trousers/jeans (one smart, one casual)
- 1× rain jacket (doubles as pillow on trains)
- 4× underwear + socks (merino dries overnight)
- 1× light fleece
- Sandals + walking shoes

**Train survival kit:**
- Eye mask + earplugs (night trains)
- Small padlock (hostel lockers)
- Packing cubes (sanity saver)
- Reusable water bottle
- €1 carabiner to clip bag to luggage rack on overnight trains

**Tech:**
- Universal adapter (1 is enough)
- Power bank 20,000mAh
- Headphones
- Offline maps downloaded (Maps.me or Google Maps offline)

**What to leave home:** Towel (most hostels provide them, or bring a fast-dry travel towel), hair dryer, more than 2 pairs of shoes.
"""),

            guide(title: "Night trains across borders: what to expect",
                  category: "Border Crossings", country: "Europe",
                  lat: 48.2082, lon: 16.3738,
                  author: authors[5],
                  likes: ["seed_user_sofia", "seed_user_jakob"],
                  content: """
Night trains are the best thing about InterRail. Here's what actually happens when you cross a border sleeping.

**Schengen crossings (e.g. Vienna→Venice, Amsterdam→Berlin):**
No passport check in most cases. Border police may board but usually only check if there's something suspicious. You won't be woken up.

**Non-Schengen crossings (UK, Croatia pre-2024, Serbia, Montenegro, Switzerland):**
Border police board the train and check every passport. For Switzerland, they're looking for EU citizens with no Schengen visa issues. For UK (Eurostar), full passport control happens before boarding, not mid-journey.

**The overnight train routine:**
1. Board 20–40 min early to stow luggage
2. Lock your compartment from inside if it has a latch
3. Use the padlock on your backpack and loop the strap around the luggage rack bar
4. Keep passport, phone, wallet in a small pouch around your neck or in the sleeping bag pocket
5. Earplugs + eye mask — you'll sleep through most of it

**Night train myths:**
- "It's dangerous" — statistically safer than a budget hostel
- "You won't sleep" — after night 2 you'll sleep like a baby
- "The compartment smells" — get a window seat and crack it 2cm
"""),

            guide(title: "Keeping your stuff safe on European trains",
                  category: "Safety", country: "Europe",
                  lat: 41.9028, lon: 12.4964,
                  author: authors[6],
                  likes: ["seed_user_anna", "seed_user_thomas", "seed_user_lena", "seed_user_marcus"],
                  content: """
Train theft exists but is massively overstated by anxious parents. A few habits eliminate nearly all risk.

**The high-risk moments:**
1. When you're distracted at a busy station (arrivals at Paris Gare du Nord, Rome Termini, Barcelona Sants)
2. When you sleep on an unsecured overnight train
3. When you leave a bag unattended "just for a second"

**The habits that work:**
- Wear your day bag on your front in crowded stations
- Luggage racks on day trains: put your bag where you can see it, never in a different carriage
- Overnight trains: padlock through the zipper, strap looped around the rack
- Valuables sleep in your sleeping bag with you, not in the overhead rack
- Photocopy your passport; keep it separately from the original

**Common scams to know:**
- "Petition" distraction — someone asks you to sign a clipboard while another picks your pocket. Wave them off without stopping.
- Fake inspectors asking to see your pass and wallet together. Real inspectors only need the pass.
- "Dropped ring" trick — someone drops a gold ring, picks it up, offers it to you as a gift, then demands money. Walk on.

**If something is stolen:** Report to local police and get a crime reference number. Your travel insurance (you have travel insurance?) needs this for claims.
"""),

            guide(title: "Best apps every InterRail traveler needs",
                  category: "Other", country: "Europe",
                  lat: 50.0755, lon: 14.4378,
                  author: authors[0],
                  likes: ["seed_user_sofia", "seed_user_mia", "seed_user_jakob", "seed_user_lena"],
                  content: """
After years of InterRail trips, these are the apps that actually live on my phone.

**Rail:**
- **DB Navigator** — German train app but works across Europe. Best real-time delay info.
- **Railplanner** — Official Eurail app. Required for digital pass activation and travel diary.
- **Trainline** — Good for booking point-to-point tickets across multiple countries in one place.
- **SNCF Connect** — Essential for anything in France. French trains won't appear correctly elsewhere.

**Accommodation:**
- **Hostelworld** — Best hostel inventory. Read reviews from the last 30 days only.
- **Booking.com** — Good last-minute finds, especially for budget hotels.

**Navigation:**
- **Maps.me** — Fully offline maps with walking directions. Download before each country.
- **Citymapper** — Best for urban transit in big cities. Covers 100+ European cities.

**Money:**
- **Wise** — Best exchange rates for spending in non-euro countries (Poland, Czech, Hungary, Croatia, Sweden). Set up before you leave.
- **Splitwise** — If traveling with friends, this handles group expenses perfectly.

**Translation:**
- **Google Translate** — Camera translation mode reads menus, signs, timetables instantly. Download offline packs.
""")
        ]

        for g in guides {
            try? await db.collection("guides").addDocument(data: g)
        }
    }

    private func guide(title: String, category: String, country: String,
                       lat: Double, lon: Double,
                       author: (id: String, name: String),
                       likes: [String], content: String) -> [String: Any] {
        [
            "title": title,
            "category": category,
            "country": country,
            "latitude": lat,
            "longitude": lon,
            "content": content,
            "createdBy": author.id,
            "authorName": author.name,
            "createdAt": Timestamp(date: randomPastDate(within: 120)),
            "updatedAt": Timestamp(date: randomPastDate(within: 30)),
            "likedBy": likes
        ]
    }

    // MARK: - Stories

    private func seedStories() async {
        let stories: [[String: Any]] = [
            story(
                title: "30 days, 8 countries, €950 — my first solo InterRail",
                author: authors[0],
                start: date(2026, 6, 1), end: date(2026, 6, 30),
                budget: 950,
                likes: ["seed_user_marcus", "seed_user_lena", "seed_user_thomas", "seed_user_jakob"],
                places: [
                    ("Amsterdam", "Netherlands", 1),
                    ("Berlin", "Germany", 2),
                    ("Prague", "Czech Republic", 3),
                    ("Vienna", "Austria", 4),
                    ("Budapest", "Hungary", 5),
                    ("Ljubljana", "Slovenia", 6),
                    ("Venice", "Italy", 7),
                    ("Paris", "France", 8)
                ],
                narrative: """
I'm writing this from my own bed, which feels unreal after a month of bunk beds and train seats. I left Amsterdam on June 1st with a 35L backpack, a Eurail Youth pass, and a spreadsheet that I abandoned somewhere around Prague.

**Amsterdam → Berlin (Day 1–4)**
The overnight ICE to Berlin was the first test. I'd never slept on a train. Turns out I'm a natural — woke up as we rolled into Berlin at 7am, stiff but alive. Berlin immediately became my favourite city: huge, weird, cheap, and full of people who seem to have figured out how to live well. Kreuzberg market on Saturday morning, five galleries in a row, a currywurst on the pavement. Perfect.

**Berlin → Prague (Day 5–8)**
Prague is a postcard that you can actually walk into. It's also the most tourist-dense place I've ever been, which means you have to work a little harder to find the real city. I hiked up to Vítkov hill at sunrise and had the view to myself. Two crowns for a tram, €2 for a beer — I spent almost nothing.

**Prague → Vienna → Budapest (Day 9–15)**
Vienna was the one place I felt like I was failing at budget travel. Coffee costs what lunch costs elsewhere. But the Opera was cheap (standing tickets, €5), the museums are world-class, and there's something about sitting in a Kaffeehaus for three hours over one coffee that feels specifically Viennese.

Budapest was the emotional peak of the trip. I swam in the Széchenyi thermal baths at 10pm, surrounded by elderly Hungarian men playing chess. I have no idea what they were saying. I floated and looked at the lit-up dome and thought: this is exactly why I did this.

**The last week**
Ljubljana surprised everyone in my hostel dorm — we all expected it to be a transit stop but ended up staying an extra day. Then Venice, which is expensive and crowded and somehow still magical at 6am before the day-trippers arrive. Paris to close it out: the Eiffel Tower was less impressive than the bakery croissant I had at 7am on the Seine.

**Numbers:**
- Nights on night trains: 6 (saved ~€150 in accommodation)
- Cheapest meal: €1.20 tram-side falafel in Vienna
- Most expensive: €45 dinner in Paris that I don't regret
- Longest train: 9 hours Vienna→Budapest (worth it for the views)

Would I do it again? I'm already planning next summer.
"""
            ),

            story(
                title: "Portugal to Poland: chasing autumn light by rail",
                author: authors[1],
                start: date(2026, 9, 10), end: date(2026, 9, 28),
                budget: 820,
                likes: ["seed_user_sofia", "seed_user_anna", "seed_user_mia"],
                places: [
                    ("Lisbon", "Portugal", 1),
                    ("Madrid", "Spain", 2),
                    ("Barcelona", "Spain", 3),
                    ("Lyon", "France", 4),
                    ("Zurich", "Switzerland", 5),
                    ("Munich", "Germany", 6),
                    ("Krakow", "Poland", 7),
                    ("Warsaw", "Poland", 8)
                ],
                narrative: """
My girlfriend thought I was crazy to start a train trip in Lisbon when I live in Stockholm. Two flights would have been faster and cheaper, but that's not the point, is it?

**Lisbon**
The pastéis de nata at Pastéis de Belém were worth the queue. Tram 28 was absolutely rammed, so we walked Alfama instead — three hours of steep cobblestones and sudden viewpoints. Lisbon rewards walking more than any city I know.

**Madrid → Barcelona**
The AVE high-speed between these two is genuinely impressive — 2.5 hours, on time, comfortable. But you pay for it: €60 each even with a pass reservation. Spain's trains are beautiful and expensive.

Barcelona gave us Gaudí overload in the best way. Sagrada Família first thing in the morning (€30 entry, book online) then the weird hills of Park Güell. The Barceloneta beach was too cold to swim but perfect to sit and eat mediocre tapas.

**Lyon → Zurich**
Lyon is criminally underrated. We had one night and spent most of it eating — bouchon Lyonnais is the French bistro tradition at its most honest. Steak, wine, cheese. Slept on the train to Zurich and arrived refreshed.

Zurich is expensive in a way that makes Vienna feel like Warsaw. A coffee is €6. But we swam in the Limmat for free and it was the highlight of the city.

**Munich → Krakow → Warsaw**
The night train to Krakow was the roughest of the trip — six berths, three of them occupied by a very snoring German man. But Krakow at 7am in autumn light makes up for anything. Wawel Castle, the old town, the Jewish Quarter — and then Auschwitz-Birkenau, which should be on every European's list regardless of the discomfort.

Warsaw closes the story with a city that shouldn't be beautiful but somehow is, rebuilt from scratch after the war and finding its own contemporary identity.

19 days, 8 countries, one lost rain jacket (Lyon, I'm still sad about it). Will absolutely do the southern route next year.
"""
            ),

            story(
                title: "Island hopping by ferry and rail: Croatia in 10 days",
                author: authors[2],
                start: date(2026, 7, 15), end: date(2026, 7, 25),
                budget: 680,
                likes: ["seed_user_thomas", "seed_user_jakob", "seed_user_sofia", "seed_user_lena", "seed_user_marcus"],
                places: [
                    ("Zagreb", "Croatia", 1),
                    ("Plitvice Lakes", "Croatia", 2),
                    ("Split", "Croatia", 3),
                    ("Hvar", "Croatia", 4),
                    ("Dubrovnik", "Croatia", 5)
                ],
                narrative: """
Croatia isn't primarily a train country — most of the coast is served by bus and ferry — but the Zagreb–Split rail line through the mountains is one of the most beautiful train journeys in Europe, and worth the trip on its own.

**Zagreb**
More than a transit city. Spent two days in the upper town, ate ćevapi and drank Ozujsko beer in outdoor kafanas. The Mirogoj cemetery sounds morbid but is genuinely one of the most architecturally beautiful cemeteries in Europe. Free entry.

**Plitvice Lakes**
Day trip by bus from Zagreb (2 hours). Yes, it's expensive (€35 high season), yes, it's crowded. Yes, it's still absolutely worth it. The turquoise water is a colour that doesn't look real.

**Zagreb to Split by train**
8 hours through the Dinaric Alps. I had a window seat and barely looked at my phone. The train winds through gorges, past medieval towns, emerges at the Dalmatian coast as the terrain shifts completely. One of Europe's great rail journeys. Book early for a seat.

**Split → Hvar → Dubrovnik**
Ferry from Split to Hvar (€12, 1 hour). Hvar town is beautiful and overrun; the villages 20 minutes inland are quiet and cheap. Kayaked around the Pakleni islands — €25 for the day. Worth it completely.

Dubrovnik by catamaran from Hvar. The old city walls cost €35 to walk — do it at 8am before the cruise ships arrive. Walked the Šulić beach area instead of the tourist trap Banje Beach.

Croatia is expensive in summer by Croatian standards but cheap by Western European ones. I spent less than I expected, saw more than I planned, and swam every single day.
"""
            ),

            story(
                title: "Scandinavia on a budget: 2 weeks, 4 countries",
                author: authors[3],
                start: date(2026, 7, 1), end: date(2026, 7, 14),
                budget: 1100,
                likes: ["seed_user_anna", "seed_user_mia"],
                places: [
                    ("Copenhagen", "Denmark", 1),
                    ("Malmö", "Sweden", 2),
                    ("Stockholm", "Sweden", 3),
                    ("Oslo", "Norway", 4),
                    ("Bergen", "Norway", 5),
                    ("Helsinki", "Finland", 6)
                ],
                narrative: """
Scandinavia is expensive. Let me say that upfront. €1,100 for 14 days feels like a lot, but this region demands it — and delivers in landscapes that justify every euro.

**Copenhagen**
The city that makes you question why everywhere doesn't have this many bikes. Cycled to the Freetown Christiania, ate a smørrebrød open sandwich, watched the sunset from Nyhavn. €25 hostel dorm was the cheapest accommodation of the whole trip.

**Malmö**
Cross the Øresund Bridge by train (15 minutes, €15) and you're in Sweden. Malmö is compact and walkable, with Moderna Museet free on Tuesdays.

**Stockholm**
Generator Stockholm hostel has a free sauna — this was the selling point and it delivered. The city is spread across 14 islands and public transport requires a day pass (€10, worth it). Gamla Stan (old town) is tourist-heavy but genuinely pretty at 7am.

**Oslo → Bergen (the Flåm Railway)**
The most expensive train in this story and the most spectacular. Oslo–Myrdal–Flåm–Bergen via the Flåmsbana railway is €80+ even with a pass (mandatory reservation). But it passes through fjords, waterfalls, and mountain terrain that doesn't look like it belongs on Earth. Not optional if you're in Norway.

Bergen's fish market is a tourist trap. Walk 15 minutes to Mathallen market instead — same fresh fish, half the price.

**Helsinki by overnight ferry**
The Silja Line Stockholm–Helsinki overnight ferry isn't covered by a rail pass, but it's €40 for a cabin and it's its own experience: a floating Scandinavian buffet that arrives in Finland at 10am.

Scandinavia rewards patience and planning. Book accommodation 3–4 weeks ahead (hostels fill up fast in July), download offline maps before you arrive, and bring a rain jacket for Norway.
"""
            ),

            story(
                title: "A long weekend in Vienna and Prague",
                author: authors[4],
                start: date(2026, 5, 22), end: date(2026, 5, 26),
                budget: 320,
                likes: ["seed_user_sofia", "seed_user_jakob"],
                places: [
                    ("Vienna", "Austria", 1),
                    ("Prague", "Czech Republic", 2)
                ],
                narrative: """
Four days, two of the most beautiful cities in Europe, €320 all-in including the train. This is the weekend trip I recommend to everyone who's never done a European rail journey.

**Vienna (Day 1–2)**
Arrived Friday morning by overnight train from Munich — slept the whole way, arrived rested and already in Austria. First stop: a Wiener Melange and a piece of Sachertorte at Café Central. Yes, it's touristy. Yes, it's still delicious.

The Belvedere museum has the original Klimt "The Kiss" and it's worth the €22 entry. The Naschmarkt food market on Saturday morning is free to wander and the döner at Yasin (just off the market) is life-changing for €3.80.

Standing tickets for the Vienna Philharmonic at the Musikverein are €5. You stand at the back but the acoustic is perfect and the experience is unlike anything else.

**Prague (Day 2–4)**
Four-hour train to Prague. The Czech countryside in late May is very green. Prague in late May is the sweet spot — before the July crowds, after the April rain.

The Charles Bridge is worth crossing once, at sunrise, before the vendors set up. Josefov (Jewish Quarter) museums are collectively €20 and sobering and important. The best view of the city isn't from the castle — it's from Vítkov Hill, free, and with approximately zero other tourists.

Czech beer at a local pub: €1.20 for a half-litre. I'm not going to pretend that wasn't a significant part of my Prague experience.

€320 breakdown: Train €95 (Munich–Vienna–Prague–Munich with Eurail Youth), Accommodation €90 (two hostel nights each city), Food €80, Museums/Tickets €55.
"""
            ),

            story(
                title: "InterRail at 52: what I wish I'd known at 22",
                author: authors[5],
                start: date(2026, 6, 10), end: date(2026, 6, 28),
                budget: 1400,
                likes: ["seed_user_lena", "seed_user_thomas", "seed_user_marcus", "seed_user_anna", "seed_user_mia", "seed_user_sofia"],
                places: [
                    ("Paris", "France", 1),
                    ("Lyon", "France", 2),
                    ("Geneva", "Switzerland", 3),
                    ("Milan", "Italy", 4),
                    ("Florence", "Italy", 5),
                    ("Rome", "Italy", 6),
                    ("Naples", "Italy", 7),
                    ("Palermo", "Italy", 8)
                ],
                narrative: """
My kids are grown. My back isn't quite what it was. I bought a 1st-class Eurail Senior pass and did 18 days of Italy and France that I'd been promising myself since 1992.

Here's what I know now that I didn't at 22.

**Slow down.** I did 8 cities in 18 days, which was the right pace — two nights minimum everywhere. At 22 I would have done twice that and remembered half as much. The point isn't the countries stamp-collecting. It's the afternoon you spend in a piazza in a city you hadn't planned to love.

**First class is worth it.** I spent my 20s in cramped couchettes. At 52, with a Senior pass discount, upgrading to 1st class is about €30–50 extra. Wider seats, real tablecloths in the dining car, quieter carriages. Not a luxury — a sustainable pace.

**Paris → Lyon by TGV**
Two hours. The speed is still thrilling. Lyon for two nights was a revelation — Paul Bocuse country, Lyonnais bouchons, serious wine. The city museum is excellent and free for over-60s.

**The Italian stretch**
Milan for the Last Supper (book weeks ahead — €20, timed entry, worth every euro), Florence for Uffizi (same — book online), Rome for a week because Rome requires a week.

Naples is misunderstood. Yes, it's chaotic. It's also the most alive city in Italy: pizza, street food, the Archaeology Museum with its Pompeii collection. And the Circumvesuviana train to Pompeii itself — €3 each way, a historical experience in its own right.

Palermo by overnight ferry from Naples. Sicily at the end of a long trip is like a reward. Different light, different pace, excellent arancini.

**What I'd tell my 22-year-old self:** The discomfort you're enduring is the wrong kind. Sleep on trains by all means — but go 2nd class couchette, not sitting-only. And spend more time in fewer places.

**What I'd tell other people my age:** The trains still run, the hostels now have private rooms, and Europe is still the best value extended travel you can do. Do not wait.
"""
            )
        ]

        for s in stories {
            try? await db.collection("tripStories").addDocument(data: s)
        }
    }

    private func story(title: String, author: (id: String, name: String),
                       start: Date, end: Date, budget: Int,
                       likes: [String],
                       places: [(city: String, country: String, order: Int)],
                       narrative: String) -> [String: Any] {
        let visitedPlaces: [[String: Any]] = places.map { place in
            [
                "id": UUID().uuidString,
                "city": place.city,
                "country": place.country,
                "order": place.order
            ]
        }
        return [
            "title": title,
            "story": narrative,
            "createdBy": author.id,
            "createdAt": Timestamp(date: randomPastDate(within: 60)),
            "updatedAt": Timestamp(date: randomPastDate(within: 20)),
            "isPublic": true,
            "tripStart": Timestamp(date: start),
            "tripEnd": Timestamp(date: end),
            "visitedPlaces": visitedPlaces,
            "photos": [],
            "viewCount": Int.random(in: 10...200),
            "likeCount": likes.count,
            "likedBy": likes,
            "budget": budget
        ]
    }

    // MARK: - Journals

    private func seedJournals() async {
        let journals: [(meta: [String: Any], entries: [[String: Any]])] = [
            (
                meta: [
                    "title": "Interrail Summer 2026",
                    "description": "My first solo rail trip through central Europe — writing as I go.",
                    "startDate": Timestamp(date: date(2026, 6, 1)),
                    "endDate": Timestamp(date: date(2026, 6, 21)),
                    "createdBy": authors[0].id,
                    "createdAt": Timestamp(date: date(2026, 6, 1)),
                    "isPublic": true,
                    "countries": ["Netherlands", "Germany", "Czech Republic", "Austria", "Hungary"]
                ],
                entries: [
                    journalEntry(journalId: "", city: "Amsterdam", country: "Netherlands",
                                 entryDate: date(2026, 6, 1), title: "Day 1 — arrived!",
                                 notes: "Train from Brussels was delayed 40 minutes but honestly it didn't matter. Amsterdam Centraal at dusk is beautiful. Found the hostel in the Jordaan, shared dorm with 5 others — a Spanish couple, a Canadian girl, and two Swedes who are doing the same route as me. First Dutch beer: Heineken, obviously wrong choice. Switched to Brouwerij 't IJ and immediately understood why people rave about Dutch craft beer. Tomorrow: bikes.",
                                 lat: 52.3791, lon: 4.9003),
                    journalEntry(journalId: "", city: "Amsterdam", country: "Netherlands",
                                 entryDate: date(2026, 6, 2), title: "Day 2 — bikes and the Rijksmuseum",
                                 notes: "Rented a bike for €10/day and cycled everywhere. The Rijksmuseum is genuinely extraordinary — Vermeer's 'The Milkmaid' in person is different from any reproduction. The light in the painting is somehow still surprising even when you know what's coming. Evening: walked Vondelpark, ate a stroopwafel warm off the street griddle (€2), watched the sunset from a bridge over the Prinsengracht.",
                                 lat: 52.3600, lon: 4.8852),
                    journalEntry(journalId: "", city: "Berlin", country: "Germany",
                                 entryDate: date(2026, 6, 4), title: "Day 4 — overnight to Berlin",
                                 notes: "The ICE night train was fine — not as comfortable as I expected, but I slept from somewhere in the middle of Germany until the outskirts of Berlin. Arrived 6:50am. Berlin feels immediately different: bigger, grittier, more industrial. Checked bags at the station (the DB locker hack works — €3 at the Ibis nearby, not €7 at the station lockers). Breakfast at a Turkish bakery, €2 for a cheese börek. Walked the East Side Gallery for two hours.",
                                 lat: 52.5251, lon: 13.3694),
                    journalEntry(journalId: "", city: "Berlin", country: "Germany",
                                 entryDate: date(2026, 6, 5), title: "Day 5 — Kreuzberg and the flea market",
                                 notes: "Saturday Mauerpark flea market. Bought a vintage Bundesbahn enamel sign for €8 that I immediately questioned whether I could carry for the rest of the trip (I'm keeping it). The karaoke amphitheatre at the flea market is a Berlin institution — hundreds of people cheering a 60-year-old man singing Sinatra. Dinner: currywurst at Curry 36, standing in the queue for 15 minutes like a local.",
                                 lat: 52.5000, lon: 13.4050),
                    journalEntry(journalId: "", city: "Prague", country: "Czech Republic",
                                 entryDate: date(2026, 6, 7), title: "Day 7 — Praha!",
                                 notes: "Four hours from Berlin. Prague from the train window: baroque towers, terracotta rooftops, the Vltava snaking through. Walked to the hostel (Wenceslas Square area, fine, €14/night) and dropped everything to walk to Vítkov hill before sunset. Was completely alone. That view — the whole city laid out, red rooftops, the castle in the background — is going on the list of best travel moments.",
                                 lat: 50.0755, lon: 14.4378),
                    journalEntry(journalId: "", city: "Vienna", country: "Austria",
                                 entryDate: date(2026, 6, 10), title: "Day 10 — Vienna and culture shock",
                                 notes: "Vienna is the most 'European' city I've been to, in the sense that it performs Europe at you. Everything is grand. The coffee is serious (Wiener Melange, not a latte, if you know what you're doing). Café Central cost €8 for a coffee and a slice of cake. Worth it once. Belvedere museum: €22, Klimt's Kiss in person: genuinely stopped me. The gold doesn't look like paint. Standing tickets at the Musikverein for €5: the acoustics are supernatural.",
                                 lat: 48.2082, lon: 16.3738),
                    journalEntry(journalId: "", city: "Budapest", country: "Hungary",
                                 entryDate: date(2026, 6, 14), title: "Day 14 — Budapest is the best city",
                                 notes: "I'm writing this from a thermal bath at 10pm. There are old men playing chess in the pool next to me. The dome above is lit gold. A beer costs €1.80 at the pool bar. Budapest is the best city I've ever been to and I've been here 12 hours. Szimpla kert ruin bar on a Tuesday: free entry, €2 beer, live jazz. Everything about this city is what travel is supposed to feel like.",
                                 lat: 47.4979, lon: 19.0402)
                ]
            ),

            (
                meta: [
                    "title": "Coastal Croatia — July 2026",
                    "description": "10 days along the Dalmatian coast. Sun, ferries, and too much seafood.",
                    "startDate": Timestamp(date: date(2026, 7, 15)),
                    "endDate": Timestamp(date: date(2026, 7, 25)),
                    "createdBy": authors[2].id,
                    "createdAt": Timestamp(date: date(2026, 7, 15)),
                    "isPublic": true,
                    "countries": ["Croatia"]
                ],
                entries: [
                    journalEntry(journalId: "", city: "Zagreb", country: "Croatia",
                                 entryDate: date(2026, 7, 15), title: "Zagreb first impressions",
                                 notes: "Landing point before heading south. Zagreb has a café culture that rivals Vienna at a quarter of the price. Upper town tram is €0.60. The Museum of Broken Relationships is one of the most original museums I've ever been in — glass cases of objects (a toaster, a wedding ring, a dress) each with a story about the relationship that ended. Surprisingly moving.",
                                 lat: 45.8150, lon: 15.9819),
                    journalEntry(journalId: "", city: "Split", country: "Croatia",
                                 entryDate: date(2026, 7, 17), title: "The Zagreb–Split train",
                                 notes: "8 hours and worth every one of them. The train climbs through the mountains, crosses several viaducts over sheer valleys, then drops down to the coast at Split. I ate a sandwich I bought at Zagreb station and didn't look at my phone once. Split: the old town is literally inside a Roman palace that Diocletian built for his retirement. People live in apartments carved into the ancient walls. Ate grilled fish at a small place off the main square, €14.",
                                 lat: 43.5081, lon: 16.4402),
                    journalEntry(journalId: "", city: "Hvar", country: "Croatia",
                                 entryDate: date(2026, 7, 19), title: "Hvar — the ferry life",
                                 notes: "Ferry from Split, 1 hour, €12. Hvar town is Instagram-beautiful and crowded. Did the right thing: rented a scooter (€25/day) and rode to Stari Grad on the other side of the island. Swam off the rocks alone for two hours. Afternoon: hiked to the Fortress above town, free entry. Best view of the harbour. Didn't go to the beach clubs — €50 minimum spend for a sunbed is not the travel I came for.",
                                 lat: 43.1729, lon: 16.4415),
                    journalEntry(journalId: "", city: "Dubrovnik", country: "Croatia",
                                 entryDate: date(2026, 7, 22), title: "Dubrovnik — beautiful and broken",
                                 notes: "Catamaran from Hvar, 2.5 hours, €35. Dubrovnik is one of the most beautiful cities I've ever seen and one of the most crowded. The cruise ships disgorge thousands of people into the old town between 10am and 6pm. I was there at 6:30am — almost entirely alone on the city walls (€35, but worth it at dawn). By 10am it was a theme park. My advice: stay two nights, see it at dawn, and spend afternoons outside the walls at the beaches. The city itself deserves better than what's happening to it.",
                                 lat: 42.6507, lon: 18.0944)
                ]
            ),

            (
                meta: [
                    "title": "Scandinavia November '25",
                    "description": "Off-season Scandinavia. Dark, expensive, absolutely stunning.",
                    "startDate": Timestamp(date: date(2025, 11, 5)),
                    "endDate": Timestamp(date: date(2025, 11, 16)),
                    "createdBy": authors[3].id,
                    "createdAt": Timestamp(date: date(2025, 11, 5)),
                    "isPublic": true,
                    "countries": ["Denmark", "Sweden", "Norway"]
                ],
                entries: [
                    journalEntry(journalId: "", city: "Copenhagen", country: "Denmark",
                                 entryDate: date(2025, 11, 5), title: "November Copenhagen",
                                 notes: "November in Copenhagen: it gets dark at 4pm and everyone seems completely fine with this. The city glows — candles in every window, fairy lights in the trees, a collectively chosen decision to be cosy. The Danish word is hygge and it doesn't translate but it feels like this. Ate a smørrebrød at Torvehallerne market for €9 and drank coffee while watching rain on the glass roof.",
                                 lat: 55.6761, lon: 12.5683),
                    journalEntry(journalId: "", city: "Stockholm", country: "Sweden",
                                 entryDate: date(2025, 11, 8), title: "Stockholm winter light",
                                 notes: "The light here in November is extraordinary — low, golden, everything looks like a painting for the two hours around midday when the sun actually appears. Gamla Stan at noon in November: tourists are gone, the cobblestones are wet, the Christmas market stalls are just setting up. Had the best cinnamon roll of my life at Fabrique bakery — queue out the door, worth every minute.",
                                 lat: 59.3293, lon: 18.0686),
                    journalEntry(journalId: "", city: "Bergen", country: "Norway",
                                 entryDate: date(2025, 11, 12), title: "Bergen and the Flåm railway",
                                 notes: "The Oslo-Myrdal-Flåm-Bergen route is one of the great train journeys of the world. In November the waterfalls are running full, the mountains have their first snow, and the fjords are mirror-flat in the grey light. I was the only person in my carriage for an hour. It cost €85 with all reservations. It is the single best €85 I have spent on travel. Bergen itself is wet (it rains 260 days a year) and beautiful and smells of fish from the market.",
                                 lat: 60.3913, lon: 5.3221)
                ]
            ),

            (
                meta: [
                    "title": "Paris → Rome, no flights",
                    "description": "A week through France and Italy by rail. Slow and intentional.",
                    "startDate": Timestamp(date: date(2026, 4, 10)),
                    "endDate": Timestamp(date: date(2026, 4, 17)),
                    "createdBy": authors[5].id,
                    "createdAt": Timestamp(date: date(2026, 4, 10)),
                    "isPublic": true,
                    "countries": ["France", "Switzerland", "Italy"]
                ],
                entries: [
                    journalEntry(journalId: "", city: "Paris", country: "France",
                                 entryDate: date(2026, 4, 10), title: "Paris, briefly",
                                 notes: "Not here to do Paris — just a night before the south. Walked to the Seine after dinner. The Eiffel Tower is lit at night and whatever you think you'll feel about it, you'll feel differently standing in front of it. Stayed at a small hotel near Gare de Lyon. The croissant at the boulangerie next door at 7am was the best I've eaten.",
                                 lat: 48.8566, lon: 2.3522),
                    journalEntry(journalId: "", city: "Lyon", country: "France",
                                 entryDate: date(2026, 4, 11), title: "Lyon: the food capital",
                                 notes: "TGV from Paris Gare de Lyon, 2 hours. Lyon is serious about food in a way that is both intimidating and wonderful. The bouchons serve traditional Lyonnais cuisine: quenelles, andouillette, tête de veau. I ordered the quenelle (a fish dumpling in beurre blanc sauce) and it was perfect. The Vieux-Lyon area is Renaissance architecture, narrow traboules (passageways through courtyards), and excellent wine bars.",
                                 lat: 45.7640, lon: 4.8357),
                    journalEntry(journalId: "", city: "Milan", country: "Italy",
                                 entryDate: date(2026, 4, 13), title: "Milan and the Last Supper",
                                 notes: "The Last Supper requires booking weeks ahead (€20, timed entry, 15 minutes inside). It is smaller than you expect and more damaged than you expect and somehow still one of the most affecting things I've encountered in a museum. The composition, even in its deteriorated state, is perfect. Milan otherwise: the Duomo's rooftop walk is excellent (€13), the Brera gallery is underrated, and the aperitivo hour (6–9pm, free food with your €8 spritz) is a civilisational achievement.",
                                 lat: 45.4642, lon: 9.1900),
                    journalEntry(journalId: "", city: "Florence", country: "Italy",
                                 entryDate: date(2026, 4, 14), title: "Florence in the rain",
                                 notes: "It rained all day and Florence was more beautiful for it. The Uffizi was uncrowded (book online, skip the queue). Botticelli's Primavera and Birth of Venus — both images you've known your whole life — are enormous, and the scale changes everything. Stood in front of the Birth of Venus for 20 minutes. Had lunch at a trattoria in the Oltrarno for €11 (pasta, wine, water). Walked back across Ponte Vecchio in the rain. Perfect day.",
                                 lat: 43.7696, lon: 11.2558),
                    journalEntry(journalId: "", city: "Rome", country: "Italy",
                                 entryDate: date(2026, 4, 15), title: "Rome: the arrival",
                                 notes: "Arrived Roma Termini and immediately got pasta at Mercato Centrale (€5, cacio e pepe, correct). Rome requires days. The Colosseum is better than you think once you're inside (book the underground tour, €18 extra, worth it). The Vatican Museums require an entire day and a great deal of patience. The Pantheon is free and extraordinary — 2,000 years old, the dome still the widest unreinforced concrete dome in the world. Drink from the nasoni fountains. Walk everywhere. The city rewards getting lost.",
                                 lat: 41.9028, lon: 12.4964)
                ]
            )
        ]

        for j in journals {
            if let ref = try? await db.collection("journals").addDocument(data: j.meta) {
                let journalId = ref.documentID
                for var entry in j.entries {
                    var e = entry
                    e["journalId"] = journalId
                    try? await db.collection("journals").document(journalId).collection("entries").addDocument(data: e)
                }
            }
        }
    }

    private func journalEntry(journalId: String, city: String, country: String,
                               entryDate: Date, title: String, notes: String,
                               lat: Double, lon: Double) -> [String: Any] {
        [
            "journalId": journalId,
            "city": city,
            "country": country,
            "date": Timestamp(date: entryDate),
            "title": title,
            "notes": notes,
            "latitude": lat,
            "longitude": lon,
            "photoURLs": [],
            "visitedTipIds": [],
            "attendedHappeningIds": [],
            "createdAt": Timestamp(date: entryDate)
        ]
    }

    // MARK: - Trips

    private func seedTrips() async {
        let trips: [[String: Any]] = [
            trip(title: "Interrail Summer 2026",
                 author: authors[0],
                 created: date(2026, 5, 20),
                 stops: [
                    stop("Amsterdam", "Netherlands", arr: date(2026, 6, 1), dep: date(2026, 6, 3), budget: 120, transport: "Train", order: 0, notes: "Book city bike for 2 days"),
                    stop("Berlin", "Germany", arr: date(2026, 6, 3), dep: date(2026, 6, 7), budget: 90, transport: "Train", order: 1, notes: "Hostel near Kreuzberg, Saturday flea market"),
                    stop("Prague", "Czech Republic", arr: date(2026, 6, 7), dep: date(2026, 6, 10), budget: 60, transport: "Train", order: 2, notes: "€1.20 trams, cheap beer"),
                    stop("Vienna", "Austria", arr: date(2026, 6, 10), dep: date(2026, 6, 13), budget: 110, transport: "Train", order: 3, notes: "Belvedere + standing opera tickets"),
                    stop("Budapest", "Hungary", arr: date(2026, 6, 13), dep: date(2026, 6, 21), budget: 80, transport: "Train", order: 4, notes: "Thermal baths, ruin bars weeknights only")
                 ],
                 plannedBudget: ["Transport": 200, "Accommodation": 350, "Food": 220, "Activities": 100, "Other": 50],
                 expenses: [
                    expense(date(2026, 6, 1), 180.0, "Transport", "Eurail Youth pass"),
                    expense(date(2026, 6, 1), 40.0, "Transport", "Train reservations"),
                    expense(date(2026, 6, 1), 14.0, "Accommodation", "Amsterdam hostel night 1"),
                    expense(date(2026, 6, 2), 14.0, "Accommodation", "Amsterdam hostel night 2"),
                    expense(date(2026, 6, 1), 10.0, "Activities", "City bike rental"),
                    expense(date(2026, 6, 2), 22.0, "Activities", "Rijksmuseum"),
                    expense(date(2026, 6, 1), 18.0, "Food", "Amsterdam day 1"),
                    expense(date(2026, 6, 2), 15.0, "Food", "Amsterdam day 2"),
                    expense(date(2026, 6, 3), 12.0, "Accommodation", "Berlin hostel night 1"),
                    expense(date(2026, 6, 4), 12.0, "Accommodation", "Berlin hostel night 2"),
                    expense(date(2026, 6, 5), 12.0, "Accommodation", "Berlin hostel night 3"),
                    expense(date(2026, 6, 6), 12.0, "Accommodation", "Berlin hostel night 4"),
                    expense(date(2026, 6, 3), 20.0, "Food", "Berlin days"),
                    expense(date(2026, 6, 5), 8.0, "Other", "Vintage sign at flea market"),
                    expense(date(2026, 6, 7), 14.0, "Accommodation", "Prague hostel night 1"),
                    expense(date(2026, 6, 8), 14.0, "Accommodation", "Prague hostel night 2"),
                    expense(date(2026, 6, 9), 14.0, "Accommodation", "Prague hostel night 3"),
                    expense(date(2026, 6, 7), 12.0, "Food", "Prague 3 days"),
                    expense(date(2026, 6, 10), 18.0, "Accommodation", "Vienna hostel night 1"),
                    expense(date(2026, 6, 11), 18.0, "Accommodation", "Vienna hostel night 2"),
                    expense(date(2026, 6, 12), 18.0, "Accommodation", "Vienna hostel night 3"),
                    expense(date(2026, 6, 10), 22.0, "Activities", "Belvedere museum"),
                    expense(date(2026, 6, 11), 5.0, "Activities", "Opera standing ticket"),
                    expense(date(2026, 6, 10), 28.0, "Food", "Vienna 3 days (expensive!)"),
                    expense(date(2026, 6, 13), 16.0, "Accommodation", "Budapest hostel night 1"),
                    expense(date(2026, 6, 14), 16.0, "Accommodation", "Budapest night 2"),
                    expense(date(2026, 6, 15), 16.0, "Accommodation", "Budapest night 3"),
                    expense(date(2026, 6, 16), 16.0, "Accommodation", "Budapest night 4"),
                    expense(date(2026, 6, 13), 15.0, "Activities", "Széchenyi thermal baths"),
                    expense(date(2026, 6, 13), 35.0, "Food", "Budapest food (so cheap)"),
                    expense(date(2026, 6, 20), 12.0, "Other", "Souvenirs")
                 ]),

            trip(title: "Coastal Croatia July",
                 author: authors[2],
                 created: date(2026, 6, 20),
                 stops: [
                    stop("Zagreb", "Croatia", arr: date(2026, 7, 15), dep: date(2026, 7, 17), budget: 80, transport: "Train", order: 0, notes: "Upper town tram, Museum of Broken Relationships"),
                    stop("Split", "Croatia", arr: date(2026, 7, 17), dep: date(2026, 7, 19), budget: 100, transport: "Train", order: 1, notes: "8hr scenic mountain route!"),
                    stop("Hvar", "Croatia", arr: date(2026, 7, 19), dep: date(2026, 7, 22), budget: 90, transport: "Ferry", order: 2, notes: "Scooter rental, avoid beach clubs"),
                    stop("Dubrovnik", "Croatia", arr: date(2026, 7, 22), dep: date(2026, 7, 25), budget: 120, transport: "Ferry", order: 3, notes: "City walls at 6:30am before crowds")
                 ],
                 plannedBudget: ["Transport": 150, "Accommodation": 250, "Food": 150, "Activities": 80, "Other": 50],
                 expenses: [
                    expense(date(2026, 7, 15), 8.0, "Transport", "Zagreb trams"),
                    expense(date(2026, 7, 17), 12.0, "Transport", "Split ferry"),
                    expense(date(2026, 7, 19), 25.0, "Transport", "Scooter rental Hvar"),
                    expense(date(2026, 7, 22), 35.0, "Transport", "Hvar–Dubrovnik catamaran"),
                    expense(date(2026, 7, 15), 22.0, "Accommodation", "Zagreb hostel 2 nights"),
                    expense(date(2026, 7, 17), 45.0, "Accommodation", "Split apartment 2 nights"),
                    expense(date(2026, 7, 19), 90.0, "Accommodation", "Hvar room 3 nights"),
                    expense(date(2026, 7, 22), 120.0, "Accommodation", "Dubrovnik (pricey!) 3 nights"),
                    expense(date(2026, 7, 15), 18.0, "Food", "Zagreb — great value"),
                    expense(date(2026, 7, 17), 28.0, "Food", "Split — grilled fish"),
                    expense(date(2026, 7, 19), 35.0, "Food", "Hvar 3 days"),
                    expense(date(2026, 7, 22), 55.0, "Food", "Dubrovnik — tourist prices"),
                    expense(date(2026, 7, 15), 10.0, "Activities", "Museum of Broken Relationships"),
                    expense(date(2026, 7, 20), 15.0, "Activities", "Kayak Pakleni islands"),
                    expense(date(2026, 7, 22), 35.0, "Activities", "Dubrovnik city walls"),
                    expense(date(2026, 7, 24), 20.0, "Other", "Croatian olive oil + wine")
                 ]),

            trip(title: "Scandinavia November",
                 author: authors[3],
                 created: date(2025, 10, 15),
                 stops: [
                    stop("Copenhagen", "Denmark", arr: date(2025, 11, 5), dep: date(2025, 11, 8), budget: 180, transport: "Train", order: 0, notes: "City bikes, Torvehallerne market"),
                    stop("Stockholm", "Sweden", arr: date(2025, 11, 8), dep: date(2025, 11, 11), budget: 200, transport: "Train", order: 1, notes: "Generator hostel, free sauna!"),
                    stop("Oslo", "Norway", arr: date(2025, 11, 11), dep: date(2025, 11, 13), budget: 220, transport: "Train", order: 2, notes: "Expensive but Munch Museum is worth it"),
                    stop("Bergen", "Norway", arr: date(2025, 11, 13), dep: date(2025, 11, 16), budget: 200, transport: "Train", order: 3, notes: "Flåm railway — BOOK THE RESERVATION")
                 ],
                 plannedBudget: ["Transport": 350, "Accommodation": 400, "Food": 250, "Activities": 120, "Other": 80],
                 expenses: [
                    expense(date(2025, 11, 5), 280.0, "Transport", "Eurail + all Scandi reservations"),
                    expense(date(2025, 11, 5), 25.0, "Accommodation", "Copenhagen hostel night 1"),
                    expense(date(2025, 11, 6), 25.0, "Accommodation", "Copenhagen night 2"),
                    expense(date(2025, 11, 7), 25.0, "Accommodation", "Copenhagen night 3"),
                    expense(date(2025, 11, 8), 28.0, "Accommodation", "Stockholm hostel night 1"),
                    expense(date(2025, 11, 9), 28.0, "Accommodation", "Stockholm night 2"),
                    expense(date(2025, 11, 10), 28.0, "Accommodation", "Stockholm night 3"),
                    expense(date(2025, 11, 11), 55.0, "Accommodation", "Oslo hostel night 1"),
                    expense(date(2025, 11, 12), 55.0, "Accommodation", "Oslo night 2"),
                    expense(date(2025, 11, 13), 60.0, "Accommodation", "Bergen hostel night 1"),
                    expense(date(2025, 11, 14), 60.0, "Accommodation", "Bergen night 2"),
                    expense(date(2025, 11, 15), 60.0, "Accommodation", "Bergen night 3"),
                    expense(date(2025, 11, 5), 42.0, "Food", "Copenhagen 3 days"),
                    expense(date(2025, 11, 8), 55.0, "Food", "Stockholm 3 days"),
                    expense(date(2025, 11, 11), 80.0, "Food", "Oslo 2 days (Norway prices!)"),
                    expense(date(2025, 11, 13), 70.0, "Food", "Bergen 3 days"),
                    expense(date(2025, 11, 6), 18.0, "Activities", "Torvehallerne + Tivoli"),
                    expense(date(2025, 11, 9), 15.0, "Activities", "Moderna Museet (Tue = free)"),
                    expense(date(2025, 11, 11), 22.0, "Activities", "Munch Museum Oslo"),
                    expense(date(2025, 11, 13), 85.0, "Activities", "Flåmsbana railway experience"),
                    expense(date(2025, 11, 15), 45.0, "Other", "Norwegian gifts, wool socks")
                 ]),

            trip(title: "Paris → Rome — spring 2026",
                 author: authors[5],
                 created: date(2026, 3, 1),
                 stops: [
                    stop("Paris", "France", arr: date(2026, 4, 10), dep: date(2026, 4, 11), budget: 100, transport: "Train", order: 0, notes: "1 night — hotel near Gare de Lyon"),
                    stop("Lyon", "France", arr: date(2026, 4, 11), dep: date(2026, 4, 13), budget: 90, transport: "Train", order: 1, notes: "Bouchon dinner, Vieux-Lyon traboules"),
                    stop("Milan", "Italy", arr: date(2026, 4, 13), dep: date(2026, 4, 14), budget: 120, transport: "Train", order: 2, notes: "Last Supper — book 3 weeks ahead!"),
                    stop("Florence", "Italy", arr: date(2026, 4, 14), dep: date(2026, 4, 15), budget: 100, transport: "Train", order: 3, notes: "Uffizi — book online, skip queue"),
                    stop("Rome", "Italy", arr: date(2026, 4, 15), dep: date(2026, 4, 17), budget: 130, transport: "Train", order: 4, notes: "Colosseum underground tour, Pantheon free, nasoni water")
                 ],
                 plannedBudget: ["Transport": 180, "Accommodation": 250, "Food": 160, "Activities": 100, "Other": 60],
                 expenses: [
                    expense(date(2026, 4, 10), 150.0, "Transport", "Eurail Senior 1st class + TGV/Frecciarossa reservations"),
                    expense(date(2026, 4, 10), 85.0, "Accommodation", "Paris hotel"),
                    expense(date(2026, 4, 11), 55.0, "Accommodation", "Lyon 2 nights"),
                    expense(date(2026, 4, 13), 70.0, "Accommodation", "Milan hotel"),
                    expense(date(2026, 4, 14), 65.0, "Accommodation", "Florence B&B"),
                    expense(date(2026, 4, 15), 80.0, "Accommodation", "Rome 2 nights"),
                    expense(date(2026, 4, 10), 22.0, "Food", "Paris dinner + breakfast"),
                    expense(date(2026, 4, 11), 35.0, "Food", "Lyon bouchon dinner"),
                    expense(date(2026, 4, 12), 20.0, "Food", "Lyon day 2"),
                    expense(date(2026, 4, 13), 28.0, "Food", "Milan aperitivo + dinner"),
                    expense(date(2026, 4, 14), 25.0, "Food", "Florence trattoria + café"),
                    expense(date(2026, 4, 15), 30.0, "Food", "Rome — Mercato Centrale + dinner"),
                    expense(date(2026, 4, 16), 22.0, "Food", "Rome day 2"),
                    expense(date(2026, 4, 13), 20.0, "Activities", "Last Supper €20, Duomo rooftop €13"),
                    expense(date(2026, 4, 14), 22.0, "Activities", "Uffizi Gallery"),
                    expense(date(2026, 4, 15), 18.0, "Activities", "Colosseum underground tour"),
                    expense(date(2026, 4, 16), 15.0, "Other", "Italian olive oil, postcard prints")
                 ])
        ]

        for t in trips {
            try? await db.collection("trips").addDocument(data: t)
        }
    }

    private func trip(title: String, author: (id: String, name: String),
                      created: Date, stops: [[String: Any]],
                      plannedBudget: [String: Double],
                      expenses: [[String: Any]]) -> [String: Any] {
        [
            "title": title,
            "createdBy": author.id,
            "createdAt": Timestamp(date: created),
            "updatedAt": Timestamp(date: created),
            "stops": stops,
            "notes": "",
            "isPublished": false,
            "plannedBudget": plannedBudget,
            "expenses": expenses
        ]
    }

    private func stop(_ city: String, _ country: String,
                      arr: Date, dep: Date,
                      budget: Int, transport: String,
                      order: Int, notes: String) -> [String: Any] {
        [
            "id": UUID().uuidString,
            "city": city,
            "country": country,
            "arrivalDate": Timestamp(date: arr),
            "departureDate": Timestamp(date: dep),
            "budgetEUR": budget,
            "transportToNext": transport,
            "order": order,
            "notes": notes,
            "accommodationNotes": ""
        ]
    }

    private func expense(_ date: Date, _ amount: Double, _ category: String, _ note: String) -> [String: Any] {
        [
            "id": UUID().uuidString,
            "date": Timestamp(date: date),
            "amount": amount,
            "category": category,
            "note": note
        ]
    }

    // MARK: - Helpers

    private func randomPastDate(within days: Int) -> Date {
        let seconds = TimeInterval.random(in: 0...(Double(days) * 86400))
        return Date().addingTimeInterval(-seconds)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}
