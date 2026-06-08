@isTest
private class HelloWorldTest {

    @isTest
    static void testHello() {
        User currentUser = [
            SELECT Id
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        System.runAs(currentUser) {
            String result = HelloWorld.sayHello();

            System.assertEquals(
                'Hello DevOps',
                result,
                'HelloWorld.sayHello should return the expected greeting.'
            );
        }
    }
}
