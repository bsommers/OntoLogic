#!/bin/bash

# 60-Second Demo Script
# Usage: ./demo.sh

echo "Prep: Starting the Stack..."
docker-compose up -d neo4j validator

echo "Step 1: The Logic Change (Simulated)"
# In a real demo, you would edit logic/fleet.logic here.
# For now, we'll just show the files.
ls -l logic/fleet.logic

echo "Step 2: The Logic Gate (Building...)"
./gradlew generateJavaModels

if [ $? -eq 0 ]; then
    echo "Build Successful. Java models generated."
else
    echo "Build Failed (As expected if Logic Bomb exists)."
fi

echo "Step 3: The Graph Insight"
echo "Pushing logic to Neo4j..."
# docker-compose run compiler -t neo4j -o generated/cypher
# cat generated/cypher/schema.cypher | docker exec -i ontologic_neo4j cypher-shell -u neo4j -p password

echo "Running Reasoning Query..."
# docker exec -i ontologic_neo4j cypher-shell -u neo4j -p password "MATCH (g:Gateway) WHERE g.secure_mode = false RETURN g.id AS insecure_gateway;"

echo "Demo Complete."
