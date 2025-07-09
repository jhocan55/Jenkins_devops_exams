#!/bin/bash


BASE_URL="http://localhost:8081/api/v1"

echo "=== Casts API ==="
echo "1. Create two new casts"
CAST_ID1=$(curl -s -X POST "$BASE_URL/casts/" \
  -H "Content-Type: application/json" \
  -d '{"name": "Leonardo DiCaprio"}' | jq '.id')
echo "Created cast 1 with ID: $CAST_ID1"

CAST_ID2=$(curl -s -X POST "$BASE_URL/casts/" \
  -H "Content-Type: application/json" \
  -d '{"name": "Carrie-Anne Moss"}' | jq '.id')
echo "Created cast 2 with ID: $CAST_ID2"
echo

echo "=== Movies API ==="
echo "2. Create a new movie using both cast IDs"
MOVIE_PAYLOAD=$(jq -n \
  --arg name "The Matrix" \
  --arg plot "A computer hacker learns about the true nature of reality." \
  --argjson genres '["Sci-Fi", "Action"]' \
  --argjson casts_id "[$CAST_ID1, $CAST_ID2]" \
  '{name: $name, plot: $plot, genres: $genres, casts_id: $casts_id}')
MOVIE_RESPONSE=$(curl -s -X POST "$BASE_URL/movies/" \
  -H "Content-Type: application/json" \
  -d "$MOVIE_PAYLOAD")
echo "POST /movies/ response:"
echo "$MOVIE_RESPONSE" | jq
MOVIE_ID=$(echo "$MOVIE_RESPONSE" | jq '.id')
echo "Created movie with ID: $MOVIE_ID"
echo

echo "3. List all movies"
MOVIES_LIST=$(curl -s -X GET "$BASE_URL/movies/")
echo "GET /movies/ response:"
echo "$MOVIES_LIST" | jq
echo

if [ -n "$MOVIE_ID" ] && [ "$MOVIE_ID" != "null" ]; then
  echo "4. Get the movie by ID"
  MOVIE_BY_ID=$(curl -s -X GET "$BASE_URL/movies/$MOVIE_ID")
  echo "GET /movies/$MOVIE_ID response:"
  echo "$MOVIE_BY_ID" | jq
  echo

  echo "5. Update the movie"
  UPDATE_PAYLOAD=$(jq -n \
    --arg name "The Matrix Reloaded" \
    --arg plot "The saga continues." \
    --argjson genres '["Sci-Fi", "Action"]' \
    --argjson casts_id "[$CAST_ID1, $CAST_ID2]" \
    '{name: $name, plot: $plot, genres: $genres, casts_id: $casts_id}')
  UPDATE_RESPONSE=$(curl -s -X PUT "$BASE_URL/movies/$MOVIE_ID" \
    -H "Content-Type: application/json" \
    -d "$UPDATE_PAYLOAD")
  echo "PUT /movies/$MOVIE_ID response:"
  echo "$UPDATE_RESPONSE" | jq
  echo

  echo "6. Delete the movie"
  DELETE_RESPONSE=$(curl -s -X DELETE "$BASE_URL/movies/$MOVIE_ID")
  echo "DELETE /movies/$MOVIE_ID response:"
  echo "$DELETE_RESPONSE" | jq
  echo
else
  echo "Movie ID not found, skipping get/update/delete movie steps."
fi

echo "7. Create a movie with only one cast"
MOVIE_PAYLOAD2=$(jq -n \
  --arg name "Interstellar" \
  --arg plot "A team travels through a wormhole in space." \
  --argjson genres '["Sci-Fi"]' \
  --argjson casts_id "[$CAST_ID1]" \
  '{name: $name, plot: $plot, genres: $genres, casts_id: $casts_id}')
MOVIE_RESPONSE2=$(curl -s -X POST "$BASE_URL/movies/" \
  -H "Content-Type: application/json" \
  -d "$MOVIE_PAYLOAD2")
echo "POST /movies/ (Interstellar) response:"
echo "$MOVIE_RESPONSE2" | jq
echo

echo "8. Try to create a movie with a non-existent cast ID"
BAD_MOVIE_PAYLOAD=$(jq -n \
  --arg name "Ghost Movie" \
  --arg plot "Should fail" \
  --argjson genres '["Horror"]' \
  --argjson casts_id '[9999]' \
  '{name: $name, plot: $plot, genres: $genres, casts_id: $casts_id}')
BAD_MOVIE_RESPONSE=$(curl -s -X POST "$BASE_URL/movies/" \
  -H "Content-Type: application/json" \
  -d "$BAD_MOVIE_PAYLOAD")
echo "POST /movies/ (bad cast) response:"
echo "$BAD_MOVIE_RESPONSE" | jq
echo

echo "=== Done! ==="
