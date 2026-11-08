import csv
import os
from neo4j import GraphDatabase

def load_data(file_path: str) -> None:
    uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
    user = os.getenv("NEO4J_USER", "neo4j")
    password = os.getenv("NEO4J_PASSWORD", "password")

    with GraphDatabase.driver(uri, auth=(user, password)) as driver:
        with driver.session() as session:
            with open(file_path, mode="r", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                for row in reader:
                    session.run("MERGE (n:Device {id: $id}) SET n += $props", id=row["id"], props=row)

if __name__ == "__main__":
    load_data("data.csv")
