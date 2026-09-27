import pandas as pd
import numpy as np
from datetime import datetime, timedelta

# ============================================================
# Synthetic Player Behavior Dataset Generator
# ============================================================
# This dataset is fully synthetic and created for educational
# and portfolio purposes.
#
# The generator creates event-level data for 2,000 players
# observed across a 30-day period.
#
# Important:
# - Behavioral tendencies are simulated internally.
# - They are NOT included in the final dataset.
# - No player segments are pre-labeled.
# - No specific "problem level" is hard-coded.
# - The goal is to let analysis discover behavioral patterns.
# ============================================================


# -----------------------------
# Reproducibility
# -----------------------------
np.random.seed(42)

NUM_PLAYERS = 2000
OBSERVATION_DAYS = 30
START_DATE = datetime(2026, 9, 1)

channels = [
    "Organic",
    "Paid_Meta",
    "Paid_Google",
    "Referral"
]

channel_probs = [
    0.40,
    0.30,
    0.20,
    0.10
]

events = []


# -----------------------------
# Helper function
# -----------------------------
def add_event(
    player_id,
    timestamp,
    session_id,
    event_name,
    level,
    attempt_number,
    feature_name,
    purchase_amount,
    acquisition_channel
):
    events.append({
        "player_id": player_id,
        "timestamp": timestamp,
        "session_id": session_id,
        "event_name": event_name,
        "level": level,
        "attempt_number": attempt_number,
        "feature_name": feature_name,
        "purchase_amount": purchase_amount,
        "acquisition_channel": acquisition_channel
    })


# ============================================================
# Hidden level difficulty structure
# ============================================================
# Difficulty is generated as a smooth, naturally varying curve.
# No specific level is manually declared as a "problem level".
# This allows later analysis to discover where friction may occur.
# ============================================================

MAX_LEVEL = 60

base_difficulty = np.linspace(
    0.25,
    0.58,
    MAX_LEVEL
)

random_variation = np.random.normal(
    0,
    0.045,
    MAX_LEVEL
)

difficulty_series = (
    pd.Series(base_difficulty + random_variation)
    .rolling(
        window=5,
        center=True,
        min_periods=1
    )
    .mean()
)

level_difficulty = np.clip(
    difficulty_series.values,
    0.20,
    0.65
)


# ============================================================
# Player simulation
# ============================================================

for i in range(1, NUM_PLAYERS + 1):

    player_id = f"P{i:04d}"

    # --------------------------------------------------------
    # Hidden behavioral tendencies
    # --------------------------------------------------------
    # These variables are only used to create realistic
    # behavioral variation. They are never written to CSV.
    # --------------------------------------------------------

    completion_tendency = np.random.beta(3, 2)
    return_tendency = np.random.beta(2.2, 2.8)
    activity_tendency = np.random.beta(2.2, 2.8)
    curiosity_tendency = np.random.beta(2, 3)
    purchase_tendency = np.random.beta(1.5, 6)
    resilience_tendency = np.random.beta(2.5, 2.5)

    channel = np.random.choice(
        channels,
        p=channel_probs
    )

    # --------------------------------------------------------
    # Installation
    # --------------------------------------------------------
    # All players enter during the first day so that the
    # dataset represents a clear 30-day observation period.
    # --------------------------------------------------------

    install_offset_minutes = np.random.uniform(
        0,
        24 * 60
    )

    install_time = (
        START_DATE
        + timedelta(minutes=install_offset_minutes)
    )

    current_level = 1
    session_num = 1

    # Features unlocked by this player
    unlocked_features = set()

    # Used to influence future return behavior
    recent_failures = 0

    # Track purchases internally
    purchase_count = 0

    # --------------------------------------------------------
    # First session / onboarding
    # --------------------------------------------------------

    session_id = f"S_{player_id}_{session_num}"

    add_event(
        player_id,
        install_time,
        session_id,
        "install",
        0,
        0,
        None,
        0.0,
        channel
    )

    current_time = install_time + timedelta(seconds=15)

    add_event(
        player_id,
        current_time,
        session_id,
        "tutorial_start",
        0,
        0,
        None,
        0.0,
        channel
    )

    # Tutorial completion varies naturally between players
    tutorial_probability = (
        0.80
        + 0.14 * activity_tendency
        + 0.04 * curiosity_tendency
    )

    tutorial_probability = np.clip(
        tutorial_probability,
        0.70,
        0.97
    )

    if np.random.random() < tutorial_probability:

        current_time += timedelta(
            seconds=np.random.randint(60, 120)
        )

        add_event(
            player_id,
            current_time,
            session_id,
            "tutorial_complete",
            0,
            0,
            None,
            0.0,
            channel
        )

    else:
        # Player leaves during onboarding.
        continue


    # ========================================================
    # 30-day observation period
    # ========================================================

    for day in range(OBSERVATION_DAYS):

        # ----------------------------------------------------
        # Determine whether player returns on this day
        # ----------------------------------------------------

        if day == 0:
            active_today = True

        else:

            # Recent friction has a temporary effect on return.
            friction_effect = min(
                recent_failures * 0.025,
                0.15
            )

            feature_bonus = min(
                len(unlocked_features) * 0.025,
                0.08
            )

            return_probability = (
                0.08
                + 0.55 * return_tendency
                + 0.16 * activity_tendency
                + feature_bonus
                - friction_effect
            )

            return_probability = np.clip(
                return_probability,
                0.03,
                0.88
            )

            active_today = (
                np.random.random()
                < return_probability
            )

        # ----------------------------------------------------
        # If player does not return, continue to next day.
        # ----------------------------------------------------

        if not active_today:

            # Friction effect gradually fades
            recent_failures = max(
                0,
                recent_failures - 1
            )

            continue

        # ----------------------------------------------------
        # Player returned
        # ----------------------------------------------------

        # Most players have one session.
        # More active players have a higher probability of
        # starting additional sessions.
        sessions_today = 1

        if np.random.random() < (
            0.20 + 0.55 * activity_tendency
        ):
            sessions_today += 1

        # A small percentage of highly active players may
        # have a third session.
        if (
            np.random.random()
            < 0.08 * activity_tendency
        ):
            sessions_today += 1

        for _ in range(sessions_today):

            session_num += 1

            session_id = (
                f"S_{player_id}_{session_num}"
            )

            # Random gap before the session
            session_gap_minutes = np.random.randint(
                5,
                180
            )

            current_time += timedelta(
                minutes=session_gap_minutes
            )

            add_event(
                player_id,
                current_time,
                session_id,
                "session_start",
                current_level,
                0,
                None,
                0.0,
                channel
            )

            # ------------------------------------------------
            # Number of levels attempted in this session
            # ------------------------------------------------

            max_levels = max(
                1,
                int(
                    2
                    + 4 * activity_tendency
                )
            )

            levels_in_session = np.random.randint(
                1,
                max_levels + 1
            )

            session_had_progress = False

            # =================================================
            # Gameplay
            # =================================================

            for _ in range(levels_in_session):

                if current_level > MAX_LEVEL:
                    break

                level_cleared = False
                attempts = 0

                # ------------------------------------------------
                # A player can make several attempts at a level.
                # ------------------------------------------------

                while (
                    not level_cleared
                    and attempts < 5
                ):

                    attempts += 1

                    current_time += timedelta(
                        seconds=np.random.randint(
                            5,
                            20
                        )
                    )

                    add_event(
                        player_id,
                        current_time,
                        session_id,
                        "level_start",
                        current_level,
                        attempts,
                        None,
                        0.0,
                        channel
                    )

                    # --------------------------------------------
                    # Level success probability
                    # --------------------------------------------

                    difficulty = level_difficulty[
                        current_level - 1
                    ]

                    success_probability = (
                        0.82
                        - difficulty
                        + 0.18 * completion_tendency
                        + 0.07 * resilience_tendency
                    )

                    # Small random session-level variation
                    success_probability += np.random.normal(
                        0,
                        0.025
                    )

                    success_probability = np.clip(
                        success_probability,
                        0.18,
                        0.92
                    )

                    level_duration = np.random.randint(
                        40,
                        120
                    )

                    current_time += timedelta(
                        seconds=level_duration
                    )

                    # ==========================================
                    # LEVEL COMPLETE
                    # ==========================================

                    if (
                        np.random.random()
                        < success_probability
                    ):

                        level_cleared = True
                        session_had_progress = True

                        add_event(
                            player_id,
                            current_time,
                            session_id,
                            "level_complete",
                            current_level,
                            attempts,
                            None,
                            0.0,
                            channel
                        )

                        # ------------------------------------
                        # Feature unlocking
                        # ------------------------------------
                        # Features become eligible at different
                        # progression points, but not every
                        # eligible player necessarily unlocks them.
                        # ------------------------------------

                        if (
                            current_level >= 3
                            and "Daily_Challenge"
                            not in unlocked_features
                        ):

                            unlock_probability = (
                                0.70
                                + 0.20 * curiosity_tendency
                            )

                            if (
                                np.random.random()
                                < unlock_probability
                            ):

                                unlocked_features.add(
                                    "Daily_Challenge"
                                )

                                add_event(
                                    player_id,
                                    current_time
                                    + timedelta(seconds=5),
                                    session_id,
                                    "feature_unlocked",
                                    current_level,
                                    attempts,
                                    "Daily_Challenge",
                                    0.0,
                                    channel
                                )

                        if (
                            current_level >= 5
                            and "Streak"
                            not in unlocked_features
                        ):

                            unlock_probability = (
                                0.60
                                + 0.25 * curiosity_tendency
                            )

                            if (
                                np.random.random()
                                < unlock_probability
                            ):

                                unlocked_features.add(
                                    "Streak"
                                )

                                add_event(
                                    player_id,
                                    current_time
                                    + timedelta(seconds=6),
                                    session_id,
                                    "feature_unlocked",
                                    current_level,
                                    attempts,
                                    "Streak",
                                    0.0,
                                    channel
                                )

                        # ------------------------------------
                        # Feature usage
                        # ------------------------------------

                        for feature in list(
                            unlocked_features
                        ):

                            feature_use_probability = (
                                0.08
                                + 0.25 * curiosity_tendency
                                + 0.20 * activity_tendency
                            )

                            if (
                                np.random.random()
                                < feature_use_probability
                            ):

                                add_event(
                                    player_id,
                                    current_time
                                    + timedelta(seconds=10),
                                    session_id,
                                    "feature_used",
                                    current_level,
                                    attempts,
                                    feature,
                                    0.0,
                                    channel
                                )

                        # Successful progress reduces
                        # accumulated friction.
                        recent_failures = max(
                            0,
                            recent_failures - 1
                        )

                        current_level += 1

                    # ==========================================
                    # LEVEL FAIL
                    # ==========================================

                    else:

                        add_event(
                            player_id,
                            current_time,
                            session_id,
                            "level_fail",
                            current_level,
                            attempts,
                            None,
                            0.0,
                            channel
                        )

                        recent_failures += 1

                        # ------------------------------------
                        # Booster usage
                        # ------------------------------------

                        booster_probability = (
                            0.05
                            + 0.18 * activity_tendency
                            + 0.12 * resilience_tendency
                        )

                        if (
                            np.random.random()
                            < booster_probability
                        ):

                            add_event(
                                player_id,
                                current_time
                                + timedelta(seconds=5),
                                session_id,
                                "booster_used",
                                current_level,
                                attempts,
                                "Booster",
                                0.0,
                                channel
                            )

                        # ------------------------------------
                        # Purchase opportunity after friction
                        # ------------------------------------

                        purchase_probability = (
                            0.008
                            + 0.025 * purchase_tendency
                            + 0.010 * activity_tendency
                        )

                        if (
                            attempts >= 2
                        ):
                            purchase_probability += 0.008

                        if (
                            np.random.random()
                            < purchase_probability
                        ):

                            purchase_count += 1

                            # Different purchase contexts
                            purchase_contexts = [
                                "Level_Continue",
                                "Booster_Pack",
                                "Streak_Recovery"
                            ]

                            purchase_context = np.random.choice(
                                purchase_contexts,
                                p=[
                                    0.45,
                                    0.35,
                                    0.20
                                ]
                            )

                            purchase_amounts = {
                                "Level_Continue": 1.99,
                                "Booster_Pack": 2.99,
                                "Streak_Recovery": 0.99
                            }

                            add_event(
                                player_id,
                                current_time
                                + timedelta(seconds=5),
                                session_id,
                                "purchase",
                                current_level,
                                attempts,
                                purchase_context,
                                purchase_amounts[
                                    purchase_context
                                ],
                                channel
                            )

                            # A purchase can provide an additional
                            # attempt, but does not automatically
                            # guarantee level completion.
                            if (
                                np.random.random()
                                < (
                                    0.30
                                    + 0.30 * resilience_tendency
                                )
                            ):
                                continue

                        # ------------------------------------
                        # Decide whether player retries
                        # ------------------------------------

                        retry_probability = (
                            0.20
                            + 0.40 * resilience_tendency
                            + 0.18 * activity_tendency
                        )

                        # Repeated failures slightly reduce
                        # the probability of another attempt.
                        retry_probability -= (
                            0.05 * max(
                                0,
                                attempts - 2
                            )
                        )

                        retry_probability = np.clip(
                            retry_probability,
                            0.08,
                            0.82
                        )

                        if (
                            np.random.random()
                            >= retry_probability
                        ):
                            break

            # =================================================
            # Additional session-level monetization
            # =================================================
            # This allows purchases to occur without a direct
            # failure → purchase relationship.
            # =================================================

            if session_had_progress:

                session_purchase_probability = (
                    0.003
                    + 0.015 * purchase_tendency
                    + 0.008 * activity_tendency
                )

                if (
                    np.random.random()
                    < session_purchase_probability
                ):

                    purchase_count += 1

                    purchase_context = np.random.choice(
                        [
                            "Booster_Pack",
                            "Daily_Challenge_Pass",
                            "Streak_Recovery"
                        ],
                        p=[
                            0.40,
                            0.35,
                            0.25
                        ]
                    )

                    purchase_amounts = {
                        "Booster_Pack": 2.99,
                        "Daily_Challenge_Pass": 1.99,
                        "Streak_Recovery": 0.99
                    }

                    add_event(
                        player_id,
                        current_time
                        + timedelta(seconds=8),
                        session_id,
                        "purchase",
                        current_level,
                        0,
                        purchase_context,
                        purchase_amounts[
                            purchase_context
                        ],
                        channel
                    )

            # ------------------------------------------------
            # Session end
            # ------------------------------------------------

            current_time += timedelta(
                seconds=np.random.randint(
                    10,
                    30
                )
            )

            add_event(
                player_id,
                current_time,
                session_id,
                "session_end",
                current_level,
                0,
                None,
                0.0,
                channel
            )

        # End of daily activity loop


# ============================================================
# Convert to DataFrame
# ============================================================

df_events = pd.DataFrame(events)


# ============================================================
# Data cleaning / ordering
# ============================================================

df_events = df_events.sort_values(
    by=[
        "player_id",
        "timestamp"
    ]
).reset_index(drop=True)


# Ensure timestamp is stored consistently
df_events["timestamp"] = pd.to_datetime(
    df_events["timestamp"]
)


# Ensure correct column order
df_events = df_events[
    [
        "player_id",
        "timestamp",
        "session_id",
        "event_name",
        "level",
        "attempt_number",
        "feature_name",
        "purchase_amount",
        "acquisition_channel"
    ]
]


# ============================================================
# Save dataset
# ============================================================

df_events.to_csv(
    "synthetic_player_events.csv",
    index=False
)


# ============================================================
# Basic validation
# ============================================================

print("Dataset generated successfully!")
print(f"Total events: {len(df_events):,}")
print(f"Unique players: {df_events['player_id'].nunique():,}")
print(
    f"Date range: "
    f"{df_events['timestamp'].min()} "
    f"→ "
    f"{df_events['timestamp'].max()}"
)

print("\nEvent distribution:")
print(
    df_events["event_name"]
    .value_counts()
    .sort_index()
)

print("\nAcquisition channels:")
print(
    df_events["acquisition_channel"]
    .value_counts()
)

print("\nPurchase events:")
print(
    (df_events["event_name"] == "purchase").sum()
)
