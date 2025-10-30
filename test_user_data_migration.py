import unittest
from unittest.mock import Mock
import os
import glob

# The get users function uses the same code in both search_user.py and update_cache.py so only importing one instance of it
from search_user import get_users_list, search_users
from update_cache import update_user_cache
from sync_password import get_password, get_cached_password, update_cached_password, sync_password

SAMPLE_FILES_DIR = "sample_files/"

class TestUserDataMigration(unittest.TestCase):
    def test_get_users_list(self):
        # Test get users list function
        expected_users = {
            "user1" : "pass1",
            "user2" : "pass2",
            "user3" : "pass356",
            "user4" : "pass4#!"
        }
        sample_users_list = SAMPLE_FILES_DIR + "test_users.txt"
        read_users = get_users_list(sample_users_list)
        self.assertDictEqual(expected_users, read_users)
    
    def test_get_users_list_no_file(self):
        # Test get users list in the case of file not existing
        with self.assertRaises(SystemExit):
            wrong_path_user_list = SAMPLE_FILES_DIR + "test_users_2.txt"
            _ = get_users_list(wrong_path_user_list)

    def test_search_users(self):
        # Test search users function
        user_list = {
            "user1" : "pass1",
            "user2" : "pass2",
            "user3" : "pass3",
            "user4" : "pass4"
        }
        users = ["user2", "user4"]
        found_users_expected = search_users(users, user_list)
        self.assertListEqual(users, found_users_expected)

        non_users = ["user5"]
        no_user_expected = search_users(non_users, user_list)
        self.assertListEqual([], no_user_expected)

    def test_get_password(self):
        # Test get password function
        users = ["user1", "user2"]
        sample_users_list = SAMPLE_FILES_DIR + "test_users.txt"

        passwords = []
        expected_passwords = ["pass1", "pass2"]
        for username in users:
            password = get_password(sample_users_list, username)
            passwords.append(password)

        self.assertListEqual(passwords, expected_passwords)

    def test_get_password_no_file(self):
        # Test get password function in the case of file not existing
        username = "user1"
        with self.assertRaises(SystemExit):
            wrong_path_user_list = SAMPLE_FILES_DIR + "test_users_2.txt"
            _ = get_password(wrong_path_user_list, username)

    def test_update_cache_and_get_cached_password(self):
        # This test relies on a cache existing so cache creation is done first
        # Test if cached passwords match expected results

        user_list = {
            "user1" : "pass1",
            "user2" : "pass2",
            "user3" : "pass3",
            "user4" : "pass4"
        }
        sample_cache = SAMPLE_FILES_DIR + "test_cache"

        # Create cache
        for user in user_list:
            update_user_cache(sample_cache, user, user_list[user])
        
        users = ["user1", "user2"]
        cache_passwords = []
        expected_cache_passwords = ["pass1", "pass2"]
        for username in users:
            cached_password = get_cached_password(sample_cache, username)
            cache_passwords.append(cached_password)

        # Check cache passwords
        self.assertListEqual(cache_passwords, expected_cache_passwords)

        # Remove cache files after test
        for filename in glob.glob(SAMPLE_FILES_DIR + "test_cache*"):
            os.remove(filename)

    def test_update_cached_password_and_get_cache_passwords(self):
        # Update cached passwords and check if they were properly updated
        user_list = {
            "user1" : "pass1",
            "user2" : "pass2",
            "user3" : "pass3",
            "user4" : "pass4"
        }
        sample_cache = SAMPLE_FILES_DIR + "test_cache"

        # Create cache
        for user in user_list:
            update_user_cache(sample_cache, user, user_list[user])

        new_users_list= {
            "user1" : "pass1new",
            "user2" : "pass2new"
        }
        # Update cache with new passwords
        for username in new_users_list:
            update_cached_password(sample_cache, username, new_users_list[username])

        cache_passwords = []
        expected_cache_passwords = ["pass1new", "pass2new", "pass3", "pass4"]
        for username in user_list.keys():
            cached_password = get_cached_password(sample_cache, username)
            cache_passwords.append(cached_password)

        # Check new cache passwords
        self.assertListEqual(cache_passwords, expected_cache_passwords)

        # Remove cache files after test
        for filename in glob.glob(SAMPLE_FILES_DIR + "test_cache*"):
            os.remove(filename)

    def test_sync_password_no_pass(self):
        # Test sync password with no password provided
        username = "user1"

        no_password_input = sync_password(username, "")
        self.assertFalse(no_password_input)

    def test_sync_password_command_fail(self):
        # Test sync password for expected fail with command
        username = "user1"
        password = "pass1"

        failed_command = sync_password(username, password)
        self.assertFalse(failed_command)

if __name__ == "__main__":
    unittest.main()