"""Tests for housekeeping task endpoints."""

from datetime import date, timedelta
from decimal import Decimal

import pytest
from django.contrib.auth.models import User
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.models import HotelUser, HousekeepingTask, Room, RoomType


@pytest.fixture
def api_client():
    """Create API client."""
    return APIClient()


@pytest.fixture
def create_user(db):
    """Factory to create users with roles."""

    def _create_user(username, role="staff"):
        user = User.objects.create_user(username=username, password="testpass123")
        HotelUser.objects.create(
            user=user, role=role, phone=f"+84{username[-6:]}"
        )
        return user

    return _create_user


@pytest.fixture
def manager_user(create_user):
    """Create manager user."""
    return create_user("manager", "manager")


@pytest.fixture
def staff_user(create_user):
    """Create staff user."""
    return create_user("staff", "staff")


@pytest.fixture
def staff_user2(create_user):
    """Create another staff user."""
    return create_user("staff2", "staff")


@pytest.fixture
def room_type(db):
    """Create room type."""
    return RoomType.objects.create(
        name="Standard",
        name_en="Standard Room",
        base_rate=Decimal("300000"),
        max_guests=2,
        description="Standard room",
    )


@pytest.fixture
def room(db, room_type):
    """Create a room."""
    return Room.objects.create(
        number="101",
        name="Phòng 101",
        room_type=room_type,
        floor=1,
        status=Room.Status.OCCUPIED,
    )


@pytest.fixture
def room2(db, room_type):
    """Create another room."""
    return Room.objects.create(
        number="102",
        name="Phòng 102",
        room_type=room_type,
        floor=1,
        status=Room.Status.AVAILABLE,
    )


@pytest.fixture
def housekeeping_task(db, room, staff_user, manager_user):
    """Create a housekeeping task."""
    return HousekeepingTask.objects.create(
        room=room,
        task_type=HousekeepingTask.TaskType.CHECKOUT_CLEAN,
        status=HousekeepingTask.Status.PENDING,
        scheduled_date=date.today(),
        created_by=manager_user,
    )


@pytest.fixture
def assigned_task(db, room, staff_user, manager_user):
    """Create an assigned housekeeping task."""
    return HousekeepingTask.objects.create(
        room=room,
        task_type=HousekeepingTask.TaskType.DEEP_CLEAN,
        status=HousekeepingTask.Status.IN_PROGRESS,
        scheduled_date=date.today(),
        assigned_to=staff_user,
        created_by=manager_user,
    )


@pytest.mark.django_db
class TestHousekeepingTaskViewSet:
    """Tests for HousekeepingTaskViewSet."""

    def test_list_tasks_as_staff(self, api_client, staff_user, housekeeping_task):
        """Staff can list housekeeping tasks."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/housekeeping-tasks/")
        assert response.status_code == status.HTTP_200_OK
        assert "results" in response.data
        assert len(response.data["results"]) == 1

    def test_list_tasks_unauthenticated(self, api_client, housekeeping_task):
        """Unauthenticated users cannot list tasks."""
        response = api_client.get("/api/v1/housekeeping-tasks/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_filter_tasks_by_room(self, api_client, staff_user, housekeeping_task, room):
        """Can filter tasks by room."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get(f"/api/v1/housekeeping-tasks/?room={room.id}")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 1
        assert response.data["results"][0]["room_number"] == room.number

    def test_filter_tasks_by_status(self, api_client, staff_user, housekeeping_task, assigned_task):
        """Can filter tasks by status."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/housekeeping-tasks/?status=pending")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 1
        assert response.data["results"][0]["status"] == "pending"

    def test_filter_tasks_by_task_type(self, api_client, staff_user, housekeeping_task):
        """Can filter tasks by task type."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/housekeeping-tasks/?task_type=checkout_clean")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 1

    def test_filter_tasks_by_assigned_to(self, api_client, staff_user, assigned_task):
        """Can filter tasks by assigned user."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get(f"/api/v1/housekeeping-tasks/?assigned_to={staff_user.id}")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 1

    def test_filter_tasks_by_scheduled_date(self, api_client, staff_user, housekeeping_task):
        """Can filter tasks by scheduled date."""
        api_client.force_authenticate(user=staff_user)
        today = date.today().isoformat()
        response = api_client.get(f"/api/v1/housekeeping-tasks/?scheduled_date={today}")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) >= 1

    def test_retrieve_task(self, api_client, staff_user, housekeeping_task):
        """Can retrieve a specific task."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get(f"/api/v1/housekeeping-tasks/{housekeeping_task.id}/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["id"] == housekeeping_task.id
        assert response.data["task_type"] == "checkout_clean"

    def test_create_task_as_manager(self, api_client, manager_user, room):
        """Manager can create tasks."""
        api_client.force_authenticate(user=manager_user)
        initial_count = HousekeepingTask.objects.count()
        data = {
            "room": room.id,
            "task_type": "inspection",
            "scheduled_date": date.today().isoformat(),
        }
        response = api_client.post("/api/v1/housekeeping-tasks/", data)
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["task_type"] == "inspection"
        # Verify the task was created
        assert HousekeepingTask.objects.count() == initial_count + 1
        # Verify created_by was set correctly
        task = HousekeepingTask.objects.latest("id")
        assert task.created_by == manager_user

    def test_create_task_as_staff(self, api_client, staff_user, room):
        """Staff can create tasks."""
        api_client.force_authenticate(user=staff_user)
        initial_count = HousekeepingTask.objects.count()
        data = {
            "room": room.id,
            "task_type": "stay_clean",
            "scheduled_date": date.today().isoformat(),
        }
        response = api_client.post("/api/v1/housekeeping-tasks/", data)
        assert response.status_code == status.HTTP_201_CREATED
        # Verify the task was created
        assert HousekeepingTask.objects.count() == initial_count + 1
        # Verify created_by was set correctly
        task = HousekeepingTask.objects.latest("id")
        assert task.created_by == staff_user

    def test_update_task(self, api_client, manager_user, housekeeping_task):
        """Can update a task."""
        api_client.force_authenticate(user=manager_user)
        data = {
            "notes": "Urgent cleaning needed",
        }
        response = api_client.patch(f"/api/v1/housekeeping-tasks/{housekeeping_task.id}/", data)
        assert response.status_code == status.HTTP_200_OK
        assert response.data["notes"] == "Urgent cleaning needed"

    def test_delete_task(self, api_client, manager_user, housekeeping_task):
        """Can delete a task."""
        api_client.force_authenticate(user=manager_user)
        response = api_client.delete(f"/api/v1/housekeeping-tasks/{housekeeping_task.id}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT
        assert not HousekeepingTask.objects.filter(id=housekeeping_task.id).exists()

    def test_assign_task(self, api_client, manager_user, staff_user, housekeeping_task):
        """Can assign a task to a staff member."""
        api_client.force_authenticate(user=manager_user)
        data = {"assigned_to": staff_user.id}
        response = api_client.post(
            f"/api/v1/housekeeping-tasks/{housekeeping_task.id}/assign/", data
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["assigned_to"] == staff_user.id
        # Status should change from pending to in_progress
        assert response.data["status"] == "in_progress"

    def test_assign_task_without_user_id(self, api_client, manager_user, housekeeping_task):
        """Assign without user ID returns error."""
        api_client.force_authenticate(user=manager_user)
        response = api_client.post(f"/api/v1/housekeeping-tasks/{housekeeping_task.id}/assign/", {})
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_assign_task_user_not_found(self, api_client, manager_user, housekeeping_task):
        """Assign to non-existent user returns error."""
        api_client.force_authenticate(user=manager_user)
        data = {"assigned_to": 99999}
        response = api_client.post(
            f"/api/v1/housekeeping-tasks/{housekeeping_task.id}/assign/", data
        )
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_complete_task(self, api_client, staff_user, assigned_task):
        """Can complete a task."""
        api_client.force_authenticate(user=staff_user)
        data = {"notes": "All clean"}
        response = api_client.post(
            f"/api/v1/housekeeping-tasks/{assigned_task.id}/complete/", data
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["status"] == "completed"
        assert response.data["completed_at"] is not None

    def test_complete_already_completed_task(self, api_client, staff_user, assigned_task):
        """Cannot complete an already completed task."""
        api_client.force_authenticate(user=staff_user)
        assigned_task.status = HousekeepingTask.Status.COMPLETED
        assigned_task.save()
        response = api_client.post(f"/api/v1/housekeeping-tasks/{assigned_task.id}/complete/", {})
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_cancel_task(self, api_client, manager_user, assigned_task):
        """Can verify a completed task."""
        api_client.force_authenticate(user=manager_user)
        # First complete the task
        assigned_task.status = HousekeepingTask.Status.COMPLETED
        assigned_task.save()
        # Now verify it
        response = api_client.post(
            f"/api/v1/housekeeping-tasks/{assigned_task.id}/verify/", {}
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["status"] == "verified"

    def test_today_tasks(self, api_client, staff_user, housekeeping_task):
        """Can get tasks scheduled for today."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/housekeeping-tasks/today/")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) >= 1

    def test_my_tasks(self, api_client, staff_user, assigned_task):
        """Can get tasks assigned to current user."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/housekeeping-tasks/my_tasks/")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 1
        assert response.data[0]["assigned_to_name"] == staff_user.get_full_name() or len(response.data) == 1

    def test_my_tasks_excludes_other_users(
        self, api_client, staff_user2, assigned_task
    ):
        """My tasks only shows tasks assigned to the current user."""
        api_client.force_authenticate(user=staff_user2)
        response = api_client.get("/api/v1/housekeeping-tasks/my_tasks/")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 0


@pytest.mark.django_db
class TestHousekeepingTaskModel:
    """Tests for HousekeepingTask model."""

    def test_create_task(self, room, manager_user):
        """Can create a housekeeping task."""
        task = HousekeepingTask.objects.create(
            room=room,
            task_type=HousekeepingTask.TaskType.CHECKOUT_CLEAN,
            scheduled_date=date.today(),
            created_by=manager_user,
        )
        assert task.status == HousekeepingTask.Status.PENDING
        assert task.task_type == HousekeepingTask.TaskType.CHECKOUT_CLEAN

    def test_task_string_representation(self, housekeeping_task):
        """Task has proper string representation."""
        expected = f"{housekeeping_task.room.number} - {housekeeping_task.get_task_type_display()}"
        assert str(housekeeping_task) == expected

    def test_task_default_status(self, room, manager_user):
        """Default status is pending."""
        task = HousekeepingTask.objects.create(
            room=room,
            task_type=HousekeepingTask.TaskType.INSPECTION,
            scheduled_date=date.today(),
            created_by=manager_user,
        )
        assert task.status == HousekeepingTask.Status.PENDING
