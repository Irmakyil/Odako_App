# Chat Service Documentation

## Overview

The ChatService provides functionality to save chat messages to Firestore within organized sessions and retrieve chat history. This is designed to support the Tiimo AI planning flow where users can send multiple consecutive messages before receiving AI responses.

## Features

### Session-Based Message Storage
- Groups messages into chat sessions for better organization
- Creates new sessions automatically when needed
- Maintains session metadata (creation time, last activity, message count)
- Supports both session-based and legacy individual message storage

### Message Queue Processing
- Supports multiple consecutive user messages
- Processes messages in order
- Generates AI responses for each user message
- Maintains UI responsiveness during processing

## Firestore Structure

### Session-Based Structure (Recommended)
```
users/{uid}/chat_sessions/{sessionId}
├── createdAt: FieldValue.serverTimestamp()
├── lastActivity: FieldValue.serverTimestamp()
├── messageCount: number
└── messages/{messageId}
    ├── message: String
    ├── sender: "user" | "ai"
    └── timestamp: FieldValue.serverTimestamp()
```

### Legacy Structure (Backward Compatible)
```
users/{uid}/chats/{messageId}
├── message: String
├── sender: "user" | "ai"
└── timestamp: FieldValue.serverTimestamp()
```

## Usage

### Session-Based Message Saving
```dart
// Create a new chat session
String sessionId = await ChatService.createChatSession();

// Save user message to session
await ChatService.saveMessageToSession(
  message: "I want to clean my room",
  sender: "user",
  sessionId: sessionId,
);

// Save AI response to session
await ChatService.saveMessageToSession(
  message: "Great! Let's start with making your bed",
  sender: "ai",
  sessionId: sessionId,
);
```

### Legacy Message Saving (Backward Compatible)
```dart
// Save user message
await ChatService.saveMessage(
  message: "I want to clean my room",
  sender: "user"
);

// Save AI response
await ChatService.saveMessage(
  message: "Great! Let's start with making your bed",
  sender: "ai"
);
```

### Getting Chat Data
```dart
// Get messages from a specific session
Stream<QuerySnapshot> sessionMessages = ChatService.getSessionMessages(sessionId);

// Get all chat sessions for the user
Stream<QuerySnapshot> chatSessions = ChatService.getChatSessions();

// Get legacy chat history (backward compatible)
Stream<QuerySnapshot> chatHistory = ChatService.getChatHistory();
```

## Error Handling

The service includes comprehensive error handling:
- Authentication errors (user not logged in)
- Invalid sender validation
- Firestore connection errors
- Graceful degradation (UI continues even if save fails)
- Session creation failures

## Migration from Legacy System

The new session-based system is backward compatible:
- Legacy `saveMessage()` method still works
- Legacy `getChatHistory()` method still works
- New session-based methods provide better organization
- Gradual migration possible

## Future Enhancements

This foundation supports:
- Task generation from AI responses within sessions
- Session-based chat history persistence
- Multi-turn conversations with context
- Session analytics and insights
- Session sharing and collaboration
- Session templates for common workflows

## Testing

Run tests with:
```bash
flutter test test/chat_service_test.dart
```

## Best Practices

1. **Use Session-Based Storage**: Prefer `saveMessageToSession()` over `saveMessage()` for new features
2. **Create Sessions Early**: Initialize sessions when starting new conversations
3. **Handle Errors Gracefully**: Always wrap calls in try-catch blocks
4. **Validate Input**: Ensure sender is either 'user' or 'ai'
5. **Monitor Performance**: Use session-based queries for better performance with large datasets 