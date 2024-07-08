import {expect, test} from "@playwright/test";

test.describe('language switcher', () => {
    test.beforeEach(async ({page}) => {
        await page.goto('http://localhost:8080');
    });

    test('has at least german and english options', async ({page}) => {
        const selectGermanEnglish = page.getByRole('combobox');
        const options = await selectGermanEnglish.locator('option').all();
        const optionValues =
            await Promise.all( options.map(async option => await option.getAttribute('value')));
        expect(optionValues.length).toBeGreaterThanOrEqual(2);
        expect(optionValues).toContain('de');
        expect(optionValues).toContain('en');
    })
});