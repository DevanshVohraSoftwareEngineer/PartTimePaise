# Firebase Data Connect Test Script

This script helps validate your Firebase Data Connect setup for the PartTimePaise task marketplace.

## Prerequisites

1. Firebase CLI installed and logged in
2. Emulators running: `firebase emulators:start --only dataconnect --project demo-project`

## Test Commands

### 1. Check Emulator Status
```bash
curl http://localhost:9399/__dataconnect/health
```

### 2. List Available Operations
```bash
curl http://localhost:9399/__dataconnect/operations
```

### 3. Test a Simple Query (Get Current User)
```bash
curl -X POST http://localhost:9399/__dataconnect/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN" \
  -d '{
    "query": "query GetCurrentUser { users { id name email profileImageUrl rating } }"
  }'
```

### 4. Test Mutation (Create User Profile)
```bash
curl -X POST http://localhost:9399/__dataconnect/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN" \
  -d '{
    "query": "mutation UpsertUserProfile($input: UserInput!) { upsertUserProfile(input: $input) { id name email } }",
    "variables": {
      "input": {
        "name": "Test User",
        "email": "test@example.com",
        "phone": "+1234567890",
        "skills": ["cleaning", "delivery"]
      }
    }
  }'
```

### 5. Test Subscription (Real-time Tasks)
```bash
curl -X POST http://localhost:9399/__dataconnect/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN" \
  -d '{
    "query": "subscription OnTaskCreated { onTaskCreated { id title description budget } }"
  }'
```

## Flutter Integration Test

Create a simple test in your Flutter app:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dataconnect_generated/generated.dart';

void testDataConnect() async {
  // Get Firebase ID token
  final user = FirebaseAuth.instance.currentUser;
  final idToken = await user?.getIdToken();

  if (idToken == null) {
    print('User not authenticated');
    return;
  }

  // Initialize Data Connect
  final dataConnect = DataConnect.instance;

  try {
    // Test GetCurrentUser query
    final userQuery = GetCurrentUserQuery();
    final userResult = await dataConnect.query(userQuery);
    print('Current user: ${userResult.data?.users.first.name}');

    // Test CreateTask mutation
    final createTask = CreateTaskMutation(
      title: 'Test Task',
      description: 'This is a test task',
      budget: 25.0,
      category: 'Test',
      location: 'Test Location',
    );
    final taskResult = await dataConnect.mutation(createTask);
    print('Created task: ${taskResult.data?.createTask.id}');

  } catch (e) {
    print('Error: $e');
  }
}
```

## Common Issues

1. **Authentication Error**: Make sure you're using a valid Firebase ID token
2. **Schema Errors**: Check the emulator logs in `dataconnect-debug.log`
3. **Connection Issues**: Ensure emulators are running on correct ports
4. **SDK Generation**: Run `firebase dataconnect:sdk:generate` after schema changes

## Next Steps

1. Generate SDKs: `firebase dataconnect:sdk:generate`
2. Integrate into Flutter app
3. Test real-time subscriptions
4. Deploy to production: `firebase deploy --only dataconnect`