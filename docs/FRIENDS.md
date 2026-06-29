# Friend Requests

Friendship writes go through authenticated Edge Functions. The iOS app should
not insert or update `friend_requests` or `friendships` directly.

## Send A Request

`POST /functions/v1/send-friend-request`

```json
{
  "recipient_user_id": "93497ccf-f296-45b2-9187-886521802c6a"
}
```

The requester ID comes from the authenticated access token.

Responses:

- `201`: request created.
- `200`: the same outgoing request is already pending.
- `404`: recipient profile not found.
- `409`: users are already friends or the recipient already sent a request.
- `422`: invalid request, including sending a request to yourself.

## Respond To A Request

`POST /functions/v1/respond-friend-request`

```json
{
  "request_id": "8bdcd6f2-b112-4755-9b6a-58d064742130",
  "action": "accepted"
}
```

`action` must be `accepted` or `rejected`. Only the recipient can respond.
Acceptance creates the normalized `friendships` row in the same database
transaction as the request update. Rejection does not create a friendship.
Repeating the same response is safe and returns `idempotent_replay: true`.

Responses:

- `200`: request accepted, rejected, or safely replayed.
- `404`: request does not exist or is not addressed to the authenticated user.
- `409`: the request was already completed with the other response.
- `422`: invalid action or request data.

## Concurrency And Security

Sending locks both profile rows in UUID order. This serializes concurrent
requests for the same pair and prevents duplicate or crossed pending requests.
The Edge Functions pass the verified user ID to service-role-only,
`security invoker` database functions. Authenticated clients retain read access
to their own requests and friendships, but direct request writes are revoked.

## Local Testing

1. Start local Supabase.
2. Sign in as the requester in Bruno.
3. Set `recipient_user_id` and run `Send Friend Request`.
4. Sign in as the recipient.
5. Run `Respond to Friend Request`.

The send request stores `friend_request_id` as a Bruno collection variable.
