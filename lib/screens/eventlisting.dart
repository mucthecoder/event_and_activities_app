import 'package:event_and_activities_app/screens/Eventspecifics.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'Event.dart';
import 'dart:convert';



class EventService {
  Future<List<Event>> fetchEvents() async {
    final response = await http.get(Uri.parse('https://eventsapi3a.azurewebsites.net/api/events/'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] && data['data'] != null) {
        return (data['data'] as List).map((eventJson) => Event.fromJson(eventJson)).toList();
      } else {
        throw Exception('Failed to load events: ${data['message'] ?? "Unknown error"}');
      }
    } else {
      throw Exception('Failed to load events');
    }
  }

  Future<List<Event>> searchEvents(String query) async {
    if (query.isEmpty) {
      // Call your get all events function here if the query is empty
      return fetchEvents();
    }

    print(query); // Debugging print statement to see the query
    final response = await http.get(Uri.parse(
        'https://eventsapi3a.azurewebsites.net/api/events/search?query=${Uri.encodeComponent(query)}'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null) {
        return (data['data'] as List)
            .map((eventJson) => Event.fromJson(eventJson))
            .toList();
      } else {
        throw Exception('Failed to load events: ${data['message'] ?? "Unknown error"}');
      }
    } else {
      throw Exception('Failed to load events');
    }
  }


  Future<List<Event>> fetchEventsByCategory(String category) async {
    final response = await http.get(Uri.parse(
        'https://eventsapi3a.azurewebsites.net/api/events?category=$category'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null) {
        return (data['data'] as List)
            .map((eventJson) => Event.fromJson(eventJson))
            .toList();
      } else {
        throw Exception('Failed to load events: ${data['message'] ?? "Unknown error"}');
      }
    } else {
      throw Exception('Failed to load events');
    }
  }
}

class EventListingPage extends StatefulWidget {
  @override
  _EventListingPageState createState() => _EventListingPageState();
}

class _EventListingPageState extends State<EventListingPage> {
  late Future<List<Event>> futureEvents;
  String searchQuery = '';
  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    futureEvents = EventService().fetchEvents(); // Initially fetch all events
  }

  void onSearch(String query) {
    setState(() {
      searchQuery = query;
      futureEvents = EventService().searchEvents(query); // Fetch events based on the search query
    });
  }

  void onCategorySelect(String category) {
    setState(() {
      selectedCategory = category;
      futureEvents = EventService().fetchEventsByCategory(category); // Fetch events by category
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: onSearch, // Call the search function on input change
            decoration: InputDecoration(
              hintText: 'Search...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CircleAvatar(
              //  backgroundImage: AssetImage('assets/wits.png'), // Replace with your image
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Filter Section
          Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                CategoryButton(categoryName: 'Education', onCategorySelect: onCategorySelect),
                CategoryButton(categoryName: 'Technology', onCategorySelect: onCategorySelect),
                CategoryButton(categoryName: 'Health', onCategorySelect: onCategorySelect),
                CategoryButton(categoryName: 'Art', onCategorySelect: onCategorySelect),
                CategoryButton(categoryName: 'Music', onCategorySelect: onCategorySelect),
                CategoryButton(categoryName: 'Free', onCategorySelect: onCategorySelect),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Upcoming Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Event List Section
          Expanded(
            child: FutureBuilder<List<Event>>(
              future: futureEvents,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No events found.'));
                }

                final events = snapshot.data!;
                return GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Adjust to your layout preference
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.7, // Aspect ratio to match the image proportions
                  ),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return EventCard(event: event);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final String categoryName;
  final Function(String) onCategorySelect;

  CategoryButton({required this.categoryName, required this.onCategorySelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        onPressed: () {
          onCategorySelect(categoryName); // Call the filter function with the selected category
        },
        child: Text(categoryName),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;

  EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(event: event),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(4.0), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), // Reduced font size
              ),
              SizedBox(height: 2), // Reduced height

              Text(
                'Author: ${event.eventAuthor}',
                style: TextStyle(fontSize: 10, color: Colors.grey), // Reduced font size
              ),
              SizedBox(height: 2), // Reduced height

              Text(
                '${event.description}',
                style: TextStyle(fontSize: 10, color: Colors.grey), // Reduced font size
              ),
              SizedBox(height: 2), // Reduced height

              Text(
                '${event.location}',
                style: TextStyle(fontSize: 10, color: Colors.grey), // Reduced font size
              ),
              SizedBox(height: 2), // Reduced height

              Text(
                'Time: ${event.startTime} - ${event.endTime}',
                style: TextStyle(fontSize: 10, color: Colors.grey), // Reduced font size
              ),
              Text(
                'Date: ${event.date}',
                style: TextStyle(fontSize: 10, color: Colors.grey), // Reduced font size
              ),
              Text(
                'Categories: ${event.categories.join(", ")}',
                style: TextStyle(fontSize: 10, color: Colors.grey), // Reduced font size
              ),
              SizedBox(height: 4), // You can adjust this as needed

              Text(
                event.isPaid ? 'Paid Event' : 'Free Event',
                style: TextStyle(
                  fontSize: 10,
                  color: event.isPaid ? Colors.red : Colors.green,
                ),
              ),

              SizedBox(height: 4), // Adjusted as needed

              Text(
                'Ticket Price: ${event.ticket_price}',
                style: TextStyle(
                  fontSize: 10,
                ),
              ),

              SizedBox(height: 4), // Adjusted as needed

              ElevatedButton(
                onPressed: () async {
                  if (event.isPaid) {
    String? name = await _showInputDialog(context, 'Enter your name');
    String? email = await _showInputDialog(context, 'Enter your email');

    if (name != null && email != null) {
      print("Event ID: ${event.event_id}");
      print("Event Date: ${event.date}");

      // Call the buyTicket function
    await buyTicket(
    eventId: event.event_id.toString(),
    ticketType: 'Paid', // Adjust as needed based on your logic
    price: double.parse(event.ticket_price),
    eventDate: event.date,
    name: name,
    email: email,
    context: context,
    );
                  } }

                  else {
                   // await getTicket(eventId: event.event_id, context: context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Your free ticket is available!'),
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: event.isPaid ? Colors.red : Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Adjusted padding
                ),
                child: Text(event.isPaid ? 'Buy Ticket' : 'Get Ticket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


Future<void> buyTicket({
  required String eventId,
  required String ticketType,
  required double price,
  required String eventDate,
  required String name,
  required String email,
  required BuildContext context,
}) async {
  print("buyTicket called with eventId: $eventId"); // Debug print
  try {
    // Retrieve the token from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    print("Retrieved Token: $token");

    // Check if the token is null
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token is null, please log in again.')),
      );
      return; // Exit the function early if there's no token
    }

    // Prepare the request body
    final Map<String, dynamic> requestBody = {
      'eventId': eventId,
      'ticketType': ticketType,
      'price': price,
      'eventDate': eventDate,
      'attendeeInfo': {
        'name': name,
        'email': email,
      },
    };

    // Make the HTTP POST request
    final response = await http.post(
      Uri.parse('https://eventsapi3a.azurewebsites.net/api/ticket/buy'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print("Response data: $responseData"); // Debug print

      // Check if the response indicates success
      if (responseData['success']) {
        if (ticketType == 'RSVP') {
          // Handle RSVP success
          final ticketId = responseData['ticket']['_id'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('RSVP successful! Ticket ID: $ticketId')),
          );
        } else {
          // Handle normal ticket purchase success
          final ticketId = responseData['ticketId'];
       //   final clientSecret = responseData['clientSecret'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ticket purchased successfully! Ticket ID: $ticketId')),
          );
          // Optionally handle payment using clientSecret if required
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${responseData['message']}')),
        );
      }
    } else if (response.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unauthorized: Please log in again.')),
      );
    } else {
      print('Error fetching ticket: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching ticket: ${response.body}')),
      );
    }
  } catch (error) {
    print('Exception occurred: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to buy ticket: $error')),
    );
  }
}


  Future<String?> _showInputDialog(BuildContext context, String title) {
    String? inputValue;
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            onChanged: (value) {
              inputValue = value;
            },
            decoration: InputDecoration(hintText: "Enter $title"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(inputValue);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
