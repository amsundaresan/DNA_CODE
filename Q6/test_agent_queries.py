"""
Simple test script: runs 3 example queries against the Clinical Trial Data Agent.
Run from the Q6 folder:  python test_agent_queries.py
"""

import sys

# Ensure we can import the agent (run from Q6 directory)
try:
    from ADAE_ClinicalTrialDataAgent import clinical_trial_data_agent
except ImportError as e:
    print("Error: Run this script from the Q6 folder.", file=sys.stderr)
    print("  cd Q6 && python test_agent_queries.py", file=sys.stderr)
    sys.exit(1)

# Example queries to run
EXAMPLE_QUERIES = [
    "Who died?",
    "Who had fractures?",
    "Who had severe events involving cancer?",
]


def main():
    print("Running 3 example queries with ClinicalTrialDataAgent\n")
    print("=" * 70)

    for i, question in enumerate(EXAMPLE_QUERIES, 1):
        print(f"\n--- Query {i}: {question} ---")
        try:
            response = clinical_trial_data_agent(question)
            parsed = response.get("parsed_filter", {})
            filters = parsed.get("filters", [])
            result = response.get("result", {})
            count = result.get("count_unique_subjects", 0)
            subjects = result.get("subjects", [])

            print(f"  Parsed filters: {len(filters)} criterion/criteria")
            for j, f in enumerate(filters, 1):
                print(f"    {j}. {f.get('target_column')} {f.get('filter_operator')} {f.get('filter_value')!r}")
            if response.get("alternative_value_used"):
                print(f"  (Used alternative value from data: {response['alternative_value_used']!r})")
            print(f"  Unique subjects: {count}")
            if subjects:
                display = subjects if len(subjects) <= 15 else subjects[:15] + [f"... and {len(subjects) - 15} more"]
                print(f"  Subjects: {display}")
        except Exception as e:
            print(f"  Error: {e}")
        print()

    print("=" * 70)
    print("Done.")


if __name__ == "__main__":
    main()
