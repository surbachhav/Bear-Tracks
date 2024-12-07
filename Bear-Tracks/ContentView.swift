//
//  ContentView.swift
//  Bear Tracks
//
//  Created by Surabhi Bachhav on 11/30/24.

import SwiftUI
import GoogleSignIn
import GoogleAPIClientForRESTCore
import GTMSessionFetcherCore

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var int = UInt64(0)
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct EventResponse: Decodable {
    let events: [Event]
}

struct Event: Identifiable, Decodable {
    let id: Int
    let name: String
    let startDate: String
    let startTime: String
    let endDate: String
    let endTime: String
    let location: String
    let eventType: String
    let organization: Organization
    let attendees: [Attendee]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case startDate = "start_date"
        case startTime = "start_time"
        case endDate = "end_date"
        case endTime = "end_time"
        case location
        case eventType = "event_type"
        case organization
        case attendees
    }
}

struct Organization: Decodable {
    let id: Int
    let name: String
    let orgType: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case orgType = "org_type"
    }
}

struct Attendee: Decodable {}

class EventViewModel: ObservableObject {
    @Published var allEvents: [Event] = []
    @Published var signedUpEvents: [Event] = []
    @Published var signedUpEventCount: Int = 0
    
    func fetchEvents() {
        guard let url = URL(string: "http://34.30.61.18/events/") else { return }
        
        let session = URLSession.shared
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching events: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decodedResponse = try JSONDecoder().decode(EventResponse.self, from: data)
                DispatchQueue.main.async {
                    self.allEvents = decodedResponse.events
                }
            } catch {
                print("Error parsing events: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func signUpForEvent(_ event: Event) {
        if !signedUpEvents.contains(where: { $0.id == event.id }) {
            signedUpEvents.append(event)
            signedUpEventCount = signedUpEvents.count
        }
    }
    
    func cancelEvent(_ event: Event) {
        signedUpEvents.removeAll { $0.id == event.id }
        signedUpEventCount = signedUpEvents.count
    }
    
}

struct ContentView: View {
    @StateObject private var viewModel = EventViewModel()
    @State private var userName: String? = "Not Signed In"
    @State private var userEmail: String? = ""
    @State private var isSignedIn: Bool = false
    @State private var userClubs: [String] = []
    
    var body: some View {
        TabView {
            DashboardView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                }
            
            ProfileView(userClubs: $userClubs)
                .tabItem {
                    Image(systemName: "person.fill")
                }
            
            GoogleSignInView(userName: $userName, userEmail: $userEmail, isSignedIn: $isSignedIn)
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                }
            
            BrowseView(viewModel: viewModel, userClubs: $userClubs)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }
            
        }
        .accentColor(.black)
        .onAppear {
            viewModel.fetchEvents()
        }
    }
}

struct GoogleSignInView: View {
    @Binding var userName: String?
    @Binding var userEmail: String?
    @Binding var isSignedIn: Bool
    
    var body: some View {
        VStack {
            if isSignedIn {
                Text("Welcome, \(userName ?? "Unknown User")!")
                    .padding()
                Text("Email: \(userEmail ?? "Unknown Email")")
                    .font(.subheadline)
                    .padding()
            } else {
                Button(action: handleSignIn) {
                    Text("Sign in with Google")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(hex: "CB1111"))
                }
                .padding(.top, -300)
            }
        }
    }
    
    func handleSignIn() {
        guard let presentingVC = UIApplication.shared.windows.first?.rootViewController else {
            print("Unable to get root view controller")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { signInResult, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                return
            }
            
            guard let user = signInResult?.user,
                  let profile = user.profile else {
                print("Failed to retrieve user profile")
                return
            }
            
            self.userName = profile.name
            self.userEmail = profile.email
            self.isSignedIn = true
        }
    }
}


struct DashboardView: View {
    
    @ObservedObject var viewModel: EventViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                
                Image("Cornell Tower")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .edgesIgnoringSafeArea(.top)
                    .mask(Rectangle().frame(height: 200).offset(y: -80))
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 4)
                
                Image("bear paws")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .position(x: 330, y: -55)
                
                Text("Coming Up")
                    .font(.title)
                    .bold()
                    .padding(.top, -270)
                
                HStack {
                    Text("Events Registered For: ")
                        .font(.title2)
                        .italic()
                    + Text("\(viewModel.signedUpEventCount)")
                        .font(.title2)
                        .bold()
                        .italic()
                }
                .padding(.top, -245)
                
                ScrollView {
                    VStack {
                        if viewModel.signedUpEvents.isEmpty {
                            Text("No events signed up yet.")
                                .foregroundColor(.black)
                                .padding(.top)
                        } else {
                            ForEach(viewModel.signedUpEvents) { event in
                                EventCard(event: event)
                                    .padding(.vertical, 10)
                            }
                        }
                    }
                    .frame(width: 300)
                }
                .padding(.top, -200)
                
                HStack {
                    Text("Bear")
                        .font(.title2)
                        .foregroundColor(.black)
                        .bold()
                    + Text(" Tracks")
                        .font(.title2)
                        .foregroundColor(Color(hex: "#CB1111"))
                        .bold()
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top)
                .padding(.horizontal, 10)
                
                Rectangle()
                    .fill(Color(hex: "#FE9797"))
                    .frame(height: 12)
                    .frame(maxWidth: .infinity)
                    .padding(.top, -10)
            }
            .background(Color(hex: "#F9F9F9"))
        }
    }
}

struct EventCard: View {
    var event: Event
    
    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: event.startDate) {
            dateFormatter.dateStyle = .long
            return dateFormatter.string(from: date)
        }
        return event.startDate
    }
    
    var formattedStartTime: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        
        var startTimeFormatted = event.startTime
        if let startTime = timeFormatter.date(from: event.startTime) {
            timeFormatter.dateFormat = "h:mm a"
            startTimeFormatted = timeFormatter.string(from: startTime)
        }
        
        return startTimeFormatted
    }
    
    var formattedEndTime: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        
        var endTimeFormatted = event.endTime
        if let endTime = timeFormatter.date(from: event.endTime) {
            timeFormatter.dateFormat = "h:mm a"
            endTimeFormatted = timeFormatter.string(from: endTime)
        }
        
        return endTimeFormatted
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .fill(Color(hex: "#D34141"))
                .frame(height: 10)
                .frame(maxWidth: .infinity)
            
            HStack {
                Spacer()
                Text(event.name)
                    .font(.title3)
                    .bold()
                Spacer()
            }
            .multilineTextAlignment(.center)
            
            Text(event.eventType)
                .font(.subheadline)
                .lineLimit(3)
                .truncationMode(.tail)
            
            HStack {
                Image("image 1")
                Text(formattedDate)
            }
            
            Text("\(formattedStartTime) - \(formattedEndTime)")
                .padding(.leading, 25)
            
            HStack {
                Image("image 3")
                Text(event.location)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(25)
        .shadow(radius: 5)
    }
}

struct ProfileView: View {
    @State private var name: String = "Enter Name Here"
    @State private var college: String = ""
    @Binding var userClubs: [String]
    @State private var newClub: String = ""
    
    let colleges = ["CAS", "CALS", "AAP", "CoE", "CHE", "Dyson", "ILR"]
    
    var body: some View {
        NavigationView {
            
            VStack (alignment: .leading) {
                
                Image("Cornell Tower")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .edgesIgnoringSafeArea(.top)
                    .mask(
                        Rectangle()
                            .frame(height: 200)
                            .offset(y: -80)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 4)
                
                HStack {
                    
                    ZStack {
                        Capsule()
                            .fill(Color(hex: "#EBDECC"))
                            .frame(height: 50)
                            .padding(.horizontal, 30)
                        
                        Image("bear paws")
                            .resizable()
                            .frame(width: 110, height: 110)
                            .offset(x: -120)
                        
                        Text("Profile")
                            .font(.title)
                            .bold()
                        
                    }
                }
                .padding(.top, -70)
                
                VStack(alignment: .leading, spacing: 15) {
                    
                    HStack {
                        Text("Name:")
                            .font(.title2)
                            .bold()
                        
                        TextField("Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("College:")
                            .font(.title2)
                            .bold()
                        Picker("Select College", selection: $college) {
                            ForEach(colleges, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    Text("Clubs:")
                        .font(.title2)
                        .bold()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(userClubs.indices, id: \.self) { index in
                                TextField("Enter Club Here", text: Binding(
                                    get: { userClubs[index] },
                                    set: { userClubs[index] = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    .frame(height: 150)
                    
                    Button(action: {
                        userClubs.append("")
                        if !newClub.isEmpty {
                            userClubs.append(newClub)
                            newClub = ""
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            
                            VStack {
                                Text("Add Club")
                                    .bold()
                                Text("Scroll to View")
                                    .italic()
                            }
                        }
                        .frame(height: 25)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "CB1111"))
                        .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 30)
                
                HStack {
                    Text("Bear")
                        .font(.title2)
                        .foregroundColor(.black)
                        .bold()
                    + Text(" Tracks")
                        .font(.title2)
                        .foregroundColor(Color(hex: "#CB1111"))
                        .bold()
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 50)
                .padding(.horizontal, 10)
                
                Rectangle()
                    .fill(Color(hex: "#FE9797"))
                    .frame(height: 12)
                    .frame(maxWidth: .infinity)
                    .padding(.top, -10)
            }
            .background(Color(hex: "#F9F9F9"))
        }
    }
}

struct BrowseView: View {
    
    @ObservedObject var viewModel: EventViewModel
    @State private var selectedFilter: String = "Choose a Filter"
    @State private var filteredEvents: [Event] = []
    @State private var currentIndex: Int = 0
    @State private var isThisWeek: Bool = false
    @Binding var userClubs: [String]
    
    func filterEvents() {
        switch selectedFilter {
            
        case "My Clubs":
            filteredEvents = viewModel.allEvents.filter { event in
                return userClubs.contains(event.organization.name)
            }
            
        case "7 AM - 12 PM":
            filteredEvents = viewModel.allEvents.filter { event in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                if let eventTime = formatter.date(from: event.startTime) {
                    let calendar = Calendar.current
                    let hour = calendar.component(.hour, from: eventTime)
                    return hour >= 7 && hour < 12
                }
                return false
            }
            
        case "12 PM - 5 PM":
            filteredEvents = viewModel.allEvents.filter { event in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                if let eventTime = formatter.date(from: event.startTime) {
                    let calendar = Calendar.current
                    let hour = calendar.component(.hour, from: eventTime)
                    return hour >= 12 && hour < 17
                }
                return false
            }
            
        case "5 PM - 10 PM":
            filteredEvents = viewModel.allEvents.filter { event in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                if let eventTime = formatter.date(from: event.startTime) {
                    let calendar = Calendar.current
                    let hour = calendar.component(.hour, from: eventTime)
                    return hour >= 17 && hour < 22
                }
                return false
            }
            
        default:
            filteredEvents = viewModel.allEvents
        }
    }
    
    func addToDashboard(event: Event) {
        viewModel.signedUpEvents.append(event)
        viewModel.signedUpEventCount += 1
    }
    
    func addEventToGoogleCalendar(event: Event, completion: @escaping (Bool) -> Void) {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("No user is signed in.")
            completion(false)
            return
        }
        
        user.refreshTokensIfNeeded { token, error in
            if let error = error {
                print("Error refreshing tokens: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let accessToken = token?.accessToken else {
                print("Access token is nil")
                completion(false)
                return
            }
            
            let calendarAPIUrl = "https://www.googleapis.com/calendar/v3/calendars/primary/events"
            
            print("Start Date: \(event.startDate)")
            print("Start Time: \(event.startTime)")

            let startDateTimeString = event.startDate + "T" + event.startTime
            let endDateTimeString = event.endDate + "T" + event.endTime

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            
            guard let startDate = dateFormatter.date(from: startDateTimeString),
                  let endDate = dateFormatter.date(from: endDateTimeString) else {
                print("Invalid date format for event.")
                print("startDateTimeString: \(startDateTimeString)")
                print("endDateTimeString: \(endDateTimeString)")
                completion(false)
                return
            }
            
            let iso8601Formatter = DateFormatter()
            iso8601Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

            let startDateString = iso8601Formatter.string(from: startDate)
            let endDateString = iso8601Formatter.string(from: endDate)
            
            print("startDateString: \(startDateString)")
            print("endDateString: \(endDateString)")

            let eventPayload: [String: Any] = [
                "summary": event.name,
                "location": event.location ?? "",
                "start": [
                    "dateTime": startDateString,
                    "timeZone": "UTC"
                ],
                "end": [
                    "dateTime": endDateString,
                    "timeZone": "UTC"
                ]
            ]
            
            print("Event Payload: \(eventPayload)")
            
            var request = URLRequest(url: URL(string: calendarAPIUrl)!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: eventPayload, options: [])
                request.httpBody = jsonData
            } catch {
                print("Error serializing JSON: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error adding event to Google Calendar: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                    
                    // Check for successful status code (200-299)
                    if (200...299).contains(httpResponse.statusCode) {
                        print("Event added to Google Calendar successfully!")
                        completion(true)
                    } else {
                        // Log the response body for debugging
                        if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                            print("Response Body: \(responseBody)")
                        }
                        print("Failed to add event to Google Calendar. Status code: \(httpResponse.statusCode)")
                        completion(false)
                    }
                }
            }
            task.resume()
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                Image("Cornell Tower")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .edgesIgnoringSafeArea(.top)
                    .mask(Rectangle().frame(height: 230).offset(y: -30))
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 4)
                    .padding(.top, -70)
                
                Text("Browse For Events")
                    .font(.title)
                    .bold()
                    .padding(.top)
                
                HStack {
                    Text("Sort By:")
                        .font(.title2)
                        .italic()
                        .padding(.top, -10)
                    
                    Picker("Filter", selection: $selectedFilter) {
                        Text("All").tag("All")
                        Text("My Clubs").tag("My Clubs")
                        Text("7 AM - 12 PM").tag("7 AM - 12 PM")
                        Text("12 PM - 5 PM").tag("12 PM - 5 PM")
                        Text("5 PM - 10 PM").tag("5 PM - 10 PM")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedFilter) { _ in
                        filterEvents()
                    }
                    .frame(height: 40)
                    .padding(.horizontal)
                    .background(Color(hex: "#CB1111"))
                    .foregroundColor(.white)
                }
                
                VStack {
                    if filteredEvents.indices.contains(currentIndex) {
                        let event = filteredEvents[currentIndex]
                        
                        EventCard(event: event)
                            .padding(.vertical, 10)
                            .frame(width: 300)
                    }
                    
                    HStack {
                        VStack {
                            Button(action: previousEvent) {
                                Image("bear-claw-two")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .scaleEffect(x: -1, y: 1)
                            }
                            Text("Back")
                                .font(.title3)
                                .italic()
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if filteredEvents.indices.contains(currentIndex) {
                                let event = filteredEvents[currentIndex]
                                addToDashboard(event: event)
                                addEventToGoogleCalendar(event: event) { success in
                                    if success {
                                        print("Event successfully added to Google Calendar!")
                                    } else {
                                        print("Failed to add event to Google Calendar.")
                                    }
                                }
                            }
                        }) {
                            Text("Add Event!")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.black)
                                .padding()
                                .background(Color(hex: "#EDD6BD"))
                        }
                        .frame(maxWidth: 300)
                        
                        Spacer()
                        
                        VStack {
                            Button(action: nextEvent) {
                                Image("bear-claw-two")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                            }
                            Text("Next")
                                .font(.title3)
                                .italic()
                        }
                    }
                    .padding(.horizontal, 45)
                    .padding(.top, 20)
                }
                .frame(height: 350)
                .onAppear {
                    filterEvents()
                }
                
                Rectangle()
                    .fill(Color(hex: "#FE9797"))
                    .frame(height: 12)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
            }
        }
        .background(Color(hex: "F9F9F9"))
    }
    
    func nextEvent() {
        if currentIndex < filteredEvents.count - 1 {
            currentIndex += 1
        }
    }
    
    func previousEvent() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
}

#Preview {
    ContentView()
}

