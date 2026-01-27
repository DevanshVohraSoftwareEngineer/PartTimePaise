# Firebase Data Connect Setup for PartTimePaise Task Marketplace

This directory contains the Firebase Data Connect configuration for the PartTimePaise task marketplace app, providing a GraphQL API with PostgreSQL backend for real-time task management, bidding, matching, and messaging.

## Overview

Firebase Data Connect offers:
- **Type-safe GraphQL API** with PostgreSQL backend
- **Real-time subscriptions** for live updates
- **Firebase Auth integration** for secure user management
- **Automatic SDK generation** for Flutter and JavaScript
- **Local development** with emulators

## Directory Structure

```
dataconnect/
├── dataconnect.yaml          # Service configuration
├── schema/
│   └── schema.gql           # GraphQL schema definition
└── example/
    ├── connector.yaml       # SDK generation config
    ├── queries.gql          # GraphQL queries
    └── mutations.gql        # GraphQL mutations
```

## Schema Overview

The schema includes the following main entities:

### Core Entities
- **User**: Firebase Auth integrated user profiles
- **Task**: Task postings with details, requirements, and status
- **Bid**: Bids placed on tasks by potential workers
- **TaskMatch**: Successful matches between task posters and workers
- **Message**: In-app messaging between matched users
- **Notification**: Push notifications and alerts
- **Payment**: Payment tracking and transaction records

### Key Relationships
- Users can post multiple tasks and place multiple bids
- Tasks can receive multiple bids
- Successful bids create TaskMatches
- Matched users can exchange Messages
- All entities support real-time updates via subscriptions

## Firebase Auth Integration

The schema uses Firebase Auth for user management:
- `auth.uid` expressions for user-specific data access
- Automatic user profile creation on first login
- Secure data isolation between users

## Available Operations

### Queries
- `GetCurrentUser`: Get authenticated user's profile
- `ListOpenTasks`: Browse available tasks with filtering
- `GetTaskDetails`: Detailed task information with bids
- `GetUserPostedTasks`: Tasks posted by current user
- `GetUserBids`: Bids placed by current user
- `GetUserMatches`: Successful matches for current user
- `GetMatchMessages`: Messages in a specific match
- `SearchTasks`: Full-text search across tasks

### Mutations
- `UpsertUserProfile`: Create/update user profile
- `CreateTask`: Post a new task
- `UpdateTask`: Modify existing task
- `PlaceBid`: Submit bid on a task
- `AcceptBid`: Accept a bid and create match
- `SendMessage`: Send message in a match
- `CompleteTaskMatch`: Mark task as completed
- `CreatePayment`: Record payment transaction

### Subscriptions
- `OnTaskCreated`: Real-time task feed
- `OnBidPlaced`: Live bid updates on tasks
- `OnMatchCreated`: Instant match notifications
- `OnMessageReceived`: Real-time messaging

## Local Development Setup

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Initialize Data Connect** (if not done):
   ```bash
   firebase init dataconnect
   ```

4. **Start local emulators**:
   ```bash
   firebase emulators:start --only dataconnect
   ```

5. **Generate SDKs**:
   ```bash
   firebase dataconnect:sdk:generate
   ```

## Flutter Integration

The connector is configured to generate a Dart SDK in:
`mobile_new/lib/dataconnect_generated/`

### Usage Example:
```dart
import 'package:dataconnect_generated/generated.dart';

// Initialize Data Connect
final dataConnect = DataConnect.instance;

// Get current user
final userQuery = GetCurrentUserQuery();
final userResult = await dataConnect.query(userQuery);

// Create a task
final createTaskMutation = CreateTaskMutation(
  title: "Clean my house",
  description: "Need help cleaning my 2-bedroom apartment",
  budget: 50.0,
  category: "Cleaning",
);
final taskResult = await dataConnect.mutation(createTaskMutation);

// Subscribe to new tasks
final subscription = OnTaskCreatedSubscription();
dataConnect.subscribe(subscription).listen((result) {
  print("New task: ${result.task.title}");
});
```

## Backend Integration

JavaScript SDKs are generated for backend services:
- `microservices/backend/src/dataconnect-generated/`
- `microservices/services/user-service/src/dataconnect-generated/`
- `microservices/services/auth-service/src/dataconnect-generated/`

## Deployment

1. **Deploy to Firebase**:
   ```bash
   firebase deploy --only dataconnect
   ```

2. **Update your app** with the deployed endpoint

## Migration from Firestore

This Data Connect setup provides:
- **Better queries**: Complex filtering, joins, aggregations
- **Real-time features**: Built-in subscriptions
- **Type safety**: Generated SDKs prevent runtime errors
- **Scalability**: PostgreSQL backend handles complex relationships

## Troubleshooting

### Common Issues:
1. **Auth not working**: Ensure Firebase Auth is properly configured
2. **SDK generation fails**: Check schema syntax and file paths
3. **Emulator issues**: Make sure PostgreSQL is running locally

### Schema Validation:
```bash
firebase dataconnect:schema:validate
```

### Logs:
```bash
firebase dataconnect:logs
```

## Next Steps

1. Test locally with emulators
2. Integrate generated SDKs into Flutter app
3. Implement real-time subscriptions
4. Deploy to production
5. Monitor performance vs Firestore

For more information, see the [Firebase Data Connect documentation](https://firebase.google.com/docs/data-connect).