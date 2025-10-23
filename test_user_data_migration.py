import unittest

# The get users function uses the same code in both search_user.py and update_cache.py so only importing one instance of it
from update_cache import get_users_list, update_user_cache
from sync_password import get_password, get_cached_password, update_cached_password, sync_password

class TestUserDataMigration(unittest.TestCase):
    def test_get_users_list(self):
        expected_users = {
            "user1" : "pass1",
            "user2" : "pass2",
            "user3" : "pass356",
            "user4" : "pass4#!"
        }
        sample_users_list = "sample_users_files/users.txt"
        read_users = get_users_list(sample_users_list)
        self.assertDictEqual(expected_users, read_users)
    
    def test_get_users_list_no_file(self):
        with self.assertRaises(SystemExit):
            wrong_path_list = "sample_users_files/users2.txt"
            read_users = get_users_list(wrong_path_list)

    def test_update_user_cache(self):
        user_list = {
            "user1" : "pass1",
            "user2" : "pass2",
            "user3" : "pass356",
            "user4" : "pass4#!"
        }

if __name__ == "__main__":
    unittest.main()